# frozen_string_literal: true

# Someone signs up with the email of an account that nobody has confirmed yet, typically a "ghost" that staff created
# for a jumper (CreateGhost). The account is claimed by whoever can read that mailbox: the confirmation email is sent
# again, and confirming it signs the person in (ConfirmUser returns credentials). Nothing the sign-up form carried (name,
# password, ...) is written to the account, because the person who typed it is not yet known to own the address: whoever
# held the link would otherwise inherit the sign-up's password. Never skips confirmation (BUG-012).
class Users::ClaimGhost < ApplicationInteraction
  string :email
  string :redirect_url

  validate :unconfirmed_account_exists

  steps :send_confirmation

  # The account for this email that is still unconfirmed, if any
  def self.pending_account(email)
    address = email.to_s.strip.downcase
    return if address.blank?

    ::User.where(confirmed_at: nil).find_by("lower(email) = :address OR lower(unconfirmed_email) = :address", address: address)
  end

  def send_confirmation
    @user.send_confirmation_instructions(redirect_url: redirect_url, template_path: ["graphql_devise/mailer"])
    @user
  end

  private

  def unconfirmed_account_exists
    @user = self.class.pending_account(email)
    errors.add(:email, "has no account waiting for confirmation") unless @user
  end
end
