# frozen_string_literal: true

require "rails_helper"

# BUG-012: signing up with the email of an account nobody has confirmed (a ghost staff created) must not hand that
# account to the person signing up. It is claimed through the confirmation email.
RSpec.describe "Claiming a ghost account" do
  include_context "dropzone"

  let(:owner_user) { create(:user) }
  let!(:owner) { create(:dropzone_user, dropzone: dropzone, user: owner_user, user_role: dropzone.user_roles.find_by(name: "owner"), credits: 500) }
  let(:student_role) { dropzone.user_roles.find_by(name: "student") }
  let(:password) { "Password1!" }
  let(:sign_up) do
    { email: "ghost@example.com", password: password, passwordConfirmation: password, name: "Impostor", phone: "1", exitWeight: 80 }
  end

  def create_ghost
    client_operation("CreateGhost", variables: { name: "Gus Ghost", email: "ghost@example.com", role: student_role.id, dropzone: dropzone.id, exitWeight: 70 }, as: owner_user)
    User.find_by!(email: "ghost@example.com")
  end

  def token_from_mail(mail)
    CGI.unescape(mail.body.to_s[/[?&;]token=([^"&]+)/, 1])
  end

  around do |example|
    previous = ENV.fetch("FRONTEND_URL", nil)
    ENV["FRONTEND_URL"] = "http://front.example.com"
    example.run
  ensure
    ENV["FRONTEND_URL"] = previous
  end

  before { ActionMailer::Base.deliveries.clear }

  it "does not change the ghost or sign anyone in" do
    ghost = create_ghost
    digest = ghost.encrypted_password

    json = client_operation("UserSignUp", variables: sign_up)

    expect(ghost.reload).to have_attributes(name: "Gus Ghost", exit_weight: 70, encrypted_password: digest, confirmed_at: nil)
    expect(ghost.valid_password?(password)).to be(false)
    expect(json.dig(:data, :userRegister, :credentials)).to be_nil
    expect(json.dig(:data, :userRegister, :authenticatable)).to be_nil
    expect(json[:errors]).to be_nil
    expect(User.where(email: "ghost@example.com").count).to eq(1)
  end

  it "sends the confirmation email to the ghost's address, not to the one who signed up" do
    create_ghost
    ActionMailer::Base.deliveries.clear

    client_operation("UserSignUp", variables: sign_up)

    expect(ActionMailer::Base.deliveries.map(&:to)).to eq([["ghost@example.com"]])
  end

  it "answers a differently cased email the same way" do
    ghost = create_ghost

    client_operation("UserSignUp", variables: sign_up.merge(email: "Ghost@Example.com"))

    expect(ghost.reload.name).to eq("Gus Ghost")
    expect(User.count { |user| user.email.casecmp?("ghost@example.com") }).to eq(1)
  end

  it "lets the owner of the mailbox claim the account by confirming, keeping its membership" do
    ghost = create_ghost
    client_operation("UserSignUp", variables: sign_up)
    token = token_from_mail(ActionMailer::Base.deliveries.last)

    json = client_operation("ConfirmUser", variables: { token: token })

    expect(json.dig(:data, :userConfirmRegistrationWithToken, :authenticatable, :id)).to eq(ghost.id.to_s)
    expect(json.dig(:data, :userConfirmRegistrationWithToken, :credentials, :uid)).to eq("ghost@example.com")
    expect(ghost.reload.confirmed_at).to be_present
    expect(ghost.dropzone_users.pluck(:dropzone_id)).to eq([dropzone.id])
    expect(ghost.valid_password?(password)).to be(false)
  end

  it "does the same for an account that signed up itself and never confirmed" do
    pending_user = create(:user, email: "later@example.com", name: "First try")
    pending_user.update_columns(confirmed_at: nil, confirmation_token: nil)

    json = client_operation("UserSignUp", variables: sign_up.merge(email: "later@example.com", name: "Second try"))

    expect(json.dig(:data, :userRegister, :credentials)).to be_nil
    expect(pending_user.reload.name).to eq("First try")
    expect(ActionMailer::Base.deliveries.last.to).to eq(["later@example.com"])
  end

  it "still refuses an email that belongs to a confirmed account" do
    create(:user, email: "taken@example.com", name: "Owner")

    json = client_operation("UserSignUp", variables: sign_up.merge(email: "taken@example.com"))

    expect(json.dig(:data, :userRegister)).to be_nil
    expect(User.find_by(email: "taken@example.com").name).to eq("Owner")
  end

  it "ignores a confirmed user's pending email change" do
    other = create(:user, email: "old@example.com")
    other.update_columns(unconfirmed_email: "ghost@example.com")

    client_operation("UserSignUp", variables: sign_up)

    expect(other.reload.name).not_to eq("Impostor")
    expect(User.find_by(email: "ghost@example.com")).to be_present
  end

  describe Users::ClaimGhost do
    it "needs an account that waits for confirmation" do
      create(:user, email: "done@example.com")

      outcome = described_class.run(email: "done@example.com", redirect_url: "https://example.com/confirm/")

      expect(outcome).not_to be_valid
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "finds an account by its email or its unconfirmed email" do
      user = create(:user, email: "a@example.com")
      user.update_columns(confirmed_at: nil, unconfirmed_email: "b@example.com")

      expect(described_class.pending_account("A@example.com")).to eq(user)
      expect(described_class.pending_account("b@example.com")).to eq(user)
      expect(described_class.pending_account("")).to be_nil
    end
  end
end
