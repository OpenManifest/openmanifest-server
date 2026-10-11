# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Client operations: auth and session" do
  let(:password) { "Password1!" }
  let(:credential_keys) { %w(accessToken tokenType client expiry uid) }

  around do |example|
    previous = ENV.fetch("FRONTEND_URL", nil)
    ENV["FRONTEND_URL"] = "http://front.example.com"
    example.run
  ensure
    ENV["FRONTEND_URL"] = previous
  end

  # Reset links carry `token`, devise confirmation links carry `confirmation_token`
  def token_from_mail(mail, param = "token")
    CGI.unescape(mail.body.to_s[/#{param}=([^"&]+)/, 1])
  end

  describe "Login" do
    let!(:user) { create(:user, password: password) }

    it "returns the user and credentials" do
      json = client_operation("Login", variables: { email: user.email, password: password })

      expect(json.dig(:data, :userLogin, :authenticatable)).to include(id: user.id.to_s, email: user.email, name: user.name)
      expect(json.dig(:data, :userLogin, :credentials).keys).to match_array(credential_keys)
      expect(json.dig(:data, :userLogin, :credentials, :uid)).to eq(user.email)
    end

    it "returns a USER_ERROR for a wrong password" do
      json = client_operation("Login", variables: { email: user.email, password: "wrong" })

      expect(json.dig(:data, :userLogin)).to be_nil
      expect(json.dig(:errors, 0, :extensions, :code)).to eq("USER_ERROR")
    end

    it "returns a USER_ERROR for an unknown email" do
      json = client_operation("Login", variables: { email: "nobody@example.com", password: password })

      expect(json.dig(:errors, 0, :message)).to match(/invalid login credentials/i)
    end
  end

  describe "UserSignUp" do
    let(:variables) do
      {
        email: "new@example.com", password: password, passwordConfirmation: password, name: "New Jumper",
        phone: "0400000000", exitWeight: 80,
      }
    end

    it "creates the user and returns credentials" do
      expect { client_operation("UserSignUp", variables: variables) }.to change(User, :count).by(1)

      json = client_operation("UserSignUp", variables: variables.merge(email: "second@example.com"))
      expect(json.dig(:data, :userRegister, :authenticatable)).to include(email: "second@example.com", name: "New Jumper")
      expect(json.dig(:data, :userRegister, :credentials).keys).to match_array(credential_keys)
      expect(json.dig(:data, :userRegister, :errors)).to be_nil
    end

    it "rejects a mismatched password confirmation" do
      json = client_operation("UserSignUp", variables: variables.merge(passwordConfirmation: "different"))

      expect(json.dig(:data, :userRegister)).to be_nil
      expect(json.dig(:errors, 0, :extensions, :detailed_errors)).to include(/confirmation/i)
      expect(User.find_by(email: "new@example.com")).to be_nil
    end

    it "rejects a missing required argument" do
      json = client_operation("UserSignUp", variables: variables.except(:name))

      expect(json[:errors].first[:message]).to match(/name/i)
    end
  end

  describe "ConfirmUser" do
    let!(:user) do
      create(:user, password: password).tap do |u|
        u.update_columns(confirmed_at: nil, confirmation_token: nil)
        ActionMailer::Base.deliveries.clear
        u.send_confirmation_instructions
      end
    end

    it "confirms the user with the emailed token and returns credentials" do
      token = token_from_mail(ActionMailer::Base.deliveries.last, "confirmation_token")

      json = client_operation("ConfirmUser", variables: { token: token })

      expect(json.dig(:data, :userConfirmRegistrationWithToken, :authenticatable, :email)).to eq(user.email)
      expect(json.dig(:data, :userConfirmRegistrationWithToken, :credentials).keys).to match_array(credential_keys)
      expect(user.reload.confirmed_at).to be_present
    end

    it "rejects an invalid token" do
      json = client_operation("ConfirmUser", variables: { token: "not-a-token" })

      expect(json.dig(:data, :userConfirmRegistrationWithToken)).to be_nil
      expect(json[:errors]).to be_present
    end
  end

  describe "RecoverPassword and UpdateLostPassword" do
    let!(:user) { create(:user, password: password) }

    it "emails a reset link and lets the user choose a new password with the token" do
      ActionMailer::Base.deliveries.clear
      json = client_operation("RecoverPassword", variables: { email: user.email, redirectUrl: "https://openmanifest.org/recover" })
      expect(json.dig(:data, :userSendPasswordResetWithToken, :message)).to match(/reset your password/i)
      token = token_from_mail(ActionMailer::Base.deliveries.last)

      json = client_operation("UpdateLostPassword", variables: { password: "NewPassword2!", passwordConfirmation: "NewPassword2!", token: token })
      expect(json.dig(:data, :userUpdatePasswordWithToken, :authenticatable, :id)).to eq(user.id.to_s)
      # graphql_devise does not sign the user in after a token reset; the client logs in again
      expect(json.dig(:data, :userUpdatePasswordWithToken, :credentials)).to be_nil

      json = client_operation("Login", variables: { email: user.email, password: "NewPassword2!" })
      expect(json.dig(:data, :userLogin, :credentials, :accessToken)).to be_present
    end

    it "returns a USER_ERROR for an unknown email" do
      json = client_operation("RecoverPassword", variables: { email: "nobody@example.com", redirectUrl: "https://openmanifest.org/recover" })

      expect(json.dig(:errors, 0, :extensions, :code)).to eq("USER_ERROR")
    end

    it "rejects an invalid reset token" do
      json = client_operation("UpdateLostPassword", variables: { password: "NewPassword2!", passwordConfirmation: "NewPassword2!", token: "bad" })

      expect(json.dig(:data, :userUpdatePasswordWithToken)).to be_nil
      expect(json[:errors]).to be_present
    end
  end

  describe "CurrentUser" do
    let!(:user) { create(:user) }

    it "returns the signed-in user" do
      json = client_operation("CurrentUser", as: user)

      expect(json.dig(:data, :currentUser)).to include(id: user.id.to_s, email: user.email, moderationRole: "user")
      expect(json.dig(:data, :currentUser, :dropzoneUsers)).to eq([])
    end

    it "requires authentication" do
      json = client_operation("CurrentUser")

      expect(json.dig(:data, :currentUser)).to be_nil
      expect(json.dig(:errors, 0, :extensions, :code)).to eq("AUTHENTICATION_ERROR")
    end
  end

  describe "LoginWithApple" do
    let(:variables) { { token: "apple.jwt.token", userIdentity: "001234.abcd" } }

    it "logs in the user resolved from the Apple token" do
      apple_user = create(:user, provider: "apple", uid: "001234.abcd")
      allow(Login::Apple).to receive(:run!).and_return(apple_user)

      json = client_operation("LoginWithApple", variables: variables)

      expect(json.dig(:data, :loginWithApple, :authenticatable, :id)).to eq(apple_user.id.to_s)
      expect(json.dig(:data, :loginWithApple, :credentials).keys).to match_array(credential_keys)
    end

    it "reports a failed Apple authentication to the client" do
      allow(Login::Apple).to receive(:run!).and_raise(StandardError, "invalid token")

      json = client_operation("LoginWithApple", variables: variables)

      expect(json).not_to have_key(:errors)
      expect(json.dig(:data, :loginWithApple, :authenticatable)).to be_nil
    end
  end

  describe "LoginWithFacebook" do
    let(:variables) { { token: "facebook-access-token" } }

    it "logs in the user resolved from the Facebook token" do
      facebook_user = create(:user, provider: "facebook", uid: "fb-1")
      allow(Login::Facebook).to receive(:run!).and_return(facebook_user)

      json = client_operation("LoginWithFacebook", variables: variables)

      expect(json.dig(:data, :loginWithFacebook, :authenticatable, :id)).to eq(facebook_user.id.to_s)
      expect(json.dig(:data, :loginWithFacebook, :credentials).keys).to match_array(credential_keys)
    end

    it "reports a failed Facebook authentication to the client" do
      allow(Login::Facebook).to receive(:run!).and_raise(StandardError, "bad token")

      json = client_operation("LoginWithFacebook", variables: variables)

      expect(json).not_to have_key(:errors)
      expect(json.dig(:data, :loginWithFacebook, :authenticatable)).to be_nil
      expect(json.dig(:data, :loginWithFacebook, :credentials)).to be_nil
    end
  end
end
