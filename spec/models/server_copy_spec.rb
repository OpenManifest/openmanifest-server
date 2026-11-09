# frozen_string_literal: true

require "rails_helper"

# P7.21: notifications, push messages and activity events use Rails I18n with the operator's terms (GENERALISATION §13)
RSpec.describe Operator, "server copy" do
  let(:skydiving) { create(:operator, credits: 0) }
  let(:trips) do
    create(:operator, credits: 0).tap do |operator|
      operator.update!(settings: operator.settings.merge("terminology" => { "load" => "Trip" }))
    end
  end

  describe "#term" do
    it "gives the template's term in the singular and the plural" do
      expect(skydiving.term(:load)).to eq("Load")
      expect(skydiving.term(:load, count: 2)).to eq("Loads")
      expect(skydiving.term(:operator)).to eq("Dropzone")
      expect(skydiving.term("crew.gca")).to eq("GCA")
    end

    it "takes the operator's override, also as a plain string" do
      expect(trips.term(:load)).to eq("Trip")
      expect(trips.term(:load, count: 3)).to eq("Trip")
    end

    it "humanises a term the terminology lacks" do
      generic = create(:operator, industry: "generic")

      expect(generic.term("crew.load_master")).to eq("Load master")
    end
  end

  describe "#translate" do
    it "fills in the terms, lower-cased mid-sentence, acronyms kept" do
      expect(skydiving.translate("activity.load.created", user: "Ann", number: 3)).to eq("Ann created Load #3")
      expect(skydiving.translate("activity.load.call_cancelled", user: "Ann", number: 3)).to eq("Ann cancelled the boarding call for Load #3")
      expect(skydiving.translate("activity.load.crew_changed", user: "Ann", number: 3, role: skydiving.term("crew.gca"), name: "Bo")).
        to eq("Ann changed the GCA for Load #3 to Bo")
    end
  end

  describe "a load's boarding call and cancellation" do
    let(:departure) { 1.hour.from_now }

    # The third load of the day, with a member on it, called
    def called_load(operator)
      vehicle = create(:vehicle, operator: operator, capacity: 14)
      load = create_list(:load, 3, vehicle: vehicle).last
      load.update!(dispatch_at: departure)
      member = create(:membership, operator: operator, credits: 500)
      create(:slot, load: load, operator: operator, membership: member, activity_type: ActivityType.allowed_for([member]).first)
      load.call!
      load
    end

    def time_at(operator) = departure.in_time_zone(operator.time_zone).strftime("%H:%M")

    it "speaks of Load #3 at a skydiving operator" do
      load = called_load(skydiving)

      expect(load.load_number).to eq(3)
      expect(Notification.where(resource: load).pluck(:message)).to eq(["Load #3: boarding call for departure at #{time_at(skydiving)}"])
      expect(Notification.where(notification_type: :user_manifested).last.message).to eq("You have been manifested on Load #3")

      load.cancel!
      expect(Notification.where(resource: load).order(:id).last.message).to eq("Load #3: boarding call cancelled")
    end

    it "speaks of Trip #3 at an operator that calls loads trips" do
      load = called_load(trips)

      expect(Notification.where(resource: load).pluck(:message)).to eq(["Trip #3: boarding call for departure at #{time_at(trips)}"])
      expect(Notification.where(notification_type: :user_manifested).last.message).to eq("You have been manifested on Trip #3")
    end
  end

  describe "activity events" do
    it "names the load in the operator's words" do
      { skydiving => "Load", trips => "Trip" }.each do |operator, word|
        manager = create(:membership, operator: operator)
        manager.grant! :deleteLoad
        load = create(:load, vehicle: create(:vehicle, operator: operator))

        Manifest::CancelLoad.run!(access_context: ApplicationInteraction::AccessContext.new(manager), load: load)

        expect(Activity::Event.where(resource: load).last.message).to eq("#{manager.user.name} cancelled #{word} ##{load.load_number}")
      end
    end
  end
end
