# frozen_string_literal: true

require "rails_helper"

# P6.18: rig inspection and credit notifications are created and delivered (BUG-042, BUG-043), invalid Expo tokens are
# cleaned, a token belongs to one user, logging out clears it (BUG-018), gauges are right (BUG-051).
RSpec.describe "Notifications and push tokens" do
  let(:dropzone) { create(:dropzone, state: "public") }
  let(:member) { create(:dropzone_user, dropzone: dropzone, credits: 100) }
  let(:expo_url) { "https://exp.host/--/api/v2/push/send" }
  let(:token) { "ExponentPushToken[abcdefghijklmnop]" }

  def notification_for(dz_user, message: "Load #1 take off at 10:00")
    Notification.create!(received_by: dz_user, message: message, resource: dropzone, notification_type: :boarding_call)
  end

  describe Notification, "#deliver" do
    before { member.user.update!(push_token: token) }

    it "posts a JSON message to Expo" do
      stub = stub_request(:post, expo_url).
        with(headers: { "Content-Type" => "application/json" },
             body: hash_including("to" => token, "title" => dropzone.name, "body" => "Load #1 take off at 10:00")).
        to_return(status: 200, body: { data: { status: "ok", id: "ticket-1" } }.to_json, headers: { "Content-Type" => "application/json" })

      notification_for(member).deliver

      expect(stub).to have_been_requested
      expect(member.user.reload.push_token).to eq(token)
    end

    it "sends nothing to a user without a push token" do
      member.user.update!(push_token: nil)

      expect { notification_for(member).deliver }.not_to raise_error
      expect(a_request(:post, expo_url)).not_to have_been_made
    end

    it "removes a token that Expo does not know (DeviceNotRegistered)" do
      body = { data: { status: "error", message: "not registered", details: { error: "DeviceNotRegistered" } } }.to_json
      stub_request(:post, expo_url).to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

      notification_for(member).deliver

      expect(member.user.reload.push_token).to be_nil
    end

    it "keeps the token after other errors of a ticket" do
      body = { data: { status: "error", message: "too many", details: { error: "MessageRateExceeded" } } }.to_json
      stub_request(:post, expo_url).to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

      notification_for(member).deliver

      expect(member.user.reload.push_token).to eq(token)
    end

    it "raises on a server error so the job retries" do
      stub_request(:post, expo_url).to_return(status: 503, body: "unavailable")

      expect { notification_for(member).deliver }.to raise_error(HTTParty::ResponseError)
      expect(member.user.reload.push_token).to eq(token)
    end

    it "does not raise when the answer is not JSON" do
      stub_request(:post, expo_url).to_return(status: 200, body: "ok")

      expect { notification_for(member).deliver }.not_to raise_error
    end
  end

  describe User, "push tokens" do
    it "takes a token from the user who had it before" do
      previous = create(:user, push_token: token)
      current = create(:user)

      current.update!(push_token: token)

      expect(previous.reload.push_token).to be_nil
      expect(current.reload.push_token).to eq(token)
    end

    it "leaves the tokens of other users alone" do
      other = create(:user, push_token: "ExponentPushToken[other]")

      create(:user).update!(push_token: token)

      expect(other.reload.push_token).to eq("ExponentPushToken[other]")
    end

    it "does not touch anybody when the token is cleared" do
      other = create(:user, push_token: "ExponentPushToken[other]")
      user = create(:user, push_token: token)

      user.update!(push_token: nil)

      expect(other.reload.push_token).to eq("ExponentPushToken[other]")
    end

    it "keeps the token when other attributes change" do
      user = create(:user, push_token: token)

      user.update!(name: "Renamed")

      expect(user.reload.push_token).to eq(token)
    end
  end

  describe RigInspection do
    let(:rig) { create(:rig, user: member.user, dropzone: nil) }
    let(:template) { create(:form_template, dropzone: dropzone) }
    let(:inspector) { create(:dropzone_user, dropzone: dropzone).tap { |inspector| inspector.grant!(:actAsRigInspector) } }

    def inspect_rig(is_ok:)
      RigInspection.create!(rig: rig, dropzone_user: member, inspected_by: inspector, form_template: template, is_ok: is_ok, definition: "[]")
    end

    it "tells the owner once when a rig is cleared to jump" do
      expect { inspect_rig(is_ok: true) }.to change { Notification.where(received_by: member, notification_type: :rig_inspection_completed).count }.by(1)
    end

    it "tells the owner when a failed inspection becomes ok, once" do
      inspection = inspect_rig(is_ok: false)

      expect { inspection.update!(is_ok: true) }.to change { Notification.where(notification_type: :rig_inspection_completed).count }.by(1)
      expect { inspection.update!(definition: "[true]") }.not_to(change { Notification.count })
    end

    it "says nothing about a failed inspection" do
      expect { inspect_rig(is_ok: false) }.not_to(change { Notification.count })
    end

    it "enqueues the push for the owner" do
      expect { inspect_rig(is_ok: true) }.to have_enqueued_job(NotifyJob)
    end
  end

  describe RequestRigInspectionJob do
    let(:rig) { create(:rig, user: member.user, dropzone: nil) }
    let!(:inspector) { create(:dropzone_user, dropzone: dropzone).tap { |inspector| inspector.grant!(:actAsRigInspector) } }
    let!(:second_inspector) { create(:dropzone_user, dropzone: dropzone).tap { |inspector| inspector.grant!(:actAsRigInspector) } }
    let!(:bystander) { create(:dropzone_user, dropzone: dropzone, user_role: dropzone.user_roles.find_by(name: "student")) }

    it "asks every rig inspector and enqueues their pushes" do
      expect { described_class.perform_now(rig.id, member.id) }.to have_enqueued_job(NotifyJob).at_least(:twice)

      asked = Notification.where(notification_type: :rig_inspection_requested, resource: rig).map(&:received_by)
      expect(asked).to contain_exactly(inspector, second_inspector)
      expect(Notification.where(notification_type: :rig_inspection_requested).first).to have_attributes(sent_by: member, message: "#{member.user.name} needs a rig inspection")
    end

    it "asks only once" do
      described_class.perform_now(rig.id, member.id)

      expect { described_class.perform_now(rig.id, member.id) }.not_to(change { Notification.count })
    end

    it "is discarded when the rig is gone" do
      expect { described_class.perform_now(0, member.id) }.not_to raise_error
    end

    it "is enqueued with ids when a member with a rig, a weight and a license joins" do
      rig
      member.user.update!(exit_weight: 80)
      joiner = create(:user, exit_weight: 80)
      create(:rig, user: joiner, dropzone: nil)

      expect { create(:dropzone_user, dropzone: dropzone, user: joiner, license: Federation.first.licenses.where.not(name: "No license").first) }.
        to have_enqueued_job(described_class).with(joiner.rigs.first.id, kind_of(Integer))
    end
  end

  describe Transaction do
    let(:order) { Order.create!(dropzone: dropzone, seller: dropzone, buyer: member) }
    let(:receipt) { Receipt.create!(order: order, amount_cents: 4000) }

    def transaction(type, receiver:, amount:, status: :reserved)
      Transaction.create!(receipt: receipt, sender: (receiver == member ? dropzone : member), receiver: receiver, amount: amount,
                          status: status, transaction_type: type, message: "x")
    end

    it "does not notify while the money is only reserved" do
      expect { transaction(:purchase, receiver: member, amount: -40) }.not_to(change { Notification.count })
    end

    it "confirms a purchase to the buyer once it is completed" do
      tx = transaction(:purchase, receiver: member, amount: -40)

      expect { tx.update!(status: :completed) }.to change { Notification.where(received_by: member, notification_type: :credits_updated).count }.by(1)
      expect(Notification.last.message).to eq("Payment of $40.00 confirmed")
    end

    it "tells the member about a refund" do
      tx = transaction(:refund, receiver: member, amount: 40)

      tx.update!(status: :completed)

      expect(Notification.last.message).to eq("$40.00 has been credited to your account")
    end

    it "tells the member about a deposit and a withdrawal" do
      transaction(:deposit, receiver: member, amount: 25, status: :completed)
      transaction(:withdrawal, receiver: member, amount: -10, status: :completed)

      expect(Notification.order(:id).last(2).map(&:message)).to eq(["$25.00 has been credited to your account", "$10.00 has been taken out of your account"])
    end

    it "does not notify the dropzone's side of a transaction" do
      expect { transaction(:sale, receiver: dropzone, amount: 40, status: :completed) }.not_to(change { Notification.count })
    end

    it "notifies only once when the transaction is saved again" do
      tx = transaction(:purchase, receiver: member, amount: -40)
      tx.update!(status: :completed)

      expect { tx.update!(message: "again") }.not_to(change { Notification.count })
    end
  end

  describe "gauges" do
    it "counts dropzones, not users, for dropzones.count" do
      allow(Appsignal).to receive(:set_gauge)
      create(:user)

      create(:dropzone)

      expect(Appsignal).to have_received(:set_gauge).with("dropzones.count", Dropzone.count)
    end
  end
end
