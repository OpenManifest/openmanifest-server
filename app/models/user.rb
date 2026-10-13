# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  provider               :string           default("email"), not null
#  uid                    :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  allow_password_change  :boolean          default(FALSE)
#  remember_created_at    :datetime
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  name                   :string
#  nickname               :string
#  image                  :string
#  phone                  :string
#  email                  :string
#  body_mass_kg            :float
#  tokens                 :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  push_token             :string
#  unconfirmed_email      :string
#  time_zone              :string           default("Australia/Brisbane")
#  load_count             :integer          default(0), not null
#  operator_count         :integer          default(0), not null
#  vehicle_count            :integer          default(0), not null
#
require "open-uri"
class User < ApplicationRecord
  include ActiveStorageSupport::SupportForBase64
  include Image::Resizer

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable
  include Discard::Model
  include GraphqlDevise::Model
  include DeviseTokenAuth::Concerns::User

  # Simple role structure for global permissions
  # Most users will have 'user', and only users with
  # permissions to manage on an organizational level
  # have anything else
  enum :moderation_role, { :user => 0, :support => 1, :moderator => 2, :administrator => 3 }

  after_create do
    Appsignal.set_gauge("users.count", User.count)
  end

  # A device has one user: whoever registers a push token takes it from every other user (the previous owner logged out
  # without clearing it, or the phone changed hands)
  before_save :release_push_token, if: -> { push_token.present? && will_save_change_to_push_token? }

  has_one_base64_attached :avatar
  resize_attached_image :avatar, size: [500, 500]

  has_many :rigs, -> { kept }
  has_many :packs
  has_many :memberships, -> { kept }
  has_many :operators, -> { kept }, through: :memberships
  has_many :slots, through: :memberships
  has_many :loads, -> { kept }, through: :slots
  has_many :user_roles, through: :memberships

  has_many :user_certifications, dependent: :destroy
  has_many :certification_levels, through: :user_certifications
  has_many :user_qualifications, through: :user_certifications
  has_many :qualifications, through: :user_qualifications

  # The level of the highest rank the user holds, among the bodies given (any when none)
  #
  # @param [Array<Integer>, nil] certification_body_ids
  # @return [CertificationLevel, nil]
  def highest_certification_level(certification_body_ids = nil)
    levels = certification_levels
    levels = levels.where(certification_body_id: certification_body_ids) unless certification_body_ids.nil?
    levels.reorder(rank: :desc, id: :desc).first
  end

  # Does the user hold the qualification and is it still valid?
  def qualified_for?(qualification)
    return true if qualification.blank?

    user_qualifications.current.exists?(qualification_id: qualification.id)
  end

  # @return [Membership, nil] the membership at the operator, nil for a user who has not joined it
  def at(operator)
    Membership.of(operator, self)
  end

  # False for a user who is not a member of the operator
  def can?(permission_name, operator_id:)
    at(operator_id)&.can?(permission_name) || false
  end

  # Compare moderation levels to get user access level
  def is_moderator?
    User.moderation_roles[moderation_role] >= User.moderation_roles["moderator"]
  end

  def self.create_fake(count: 1)
    random_user_url = URI.open("https://randomuser.me/api/?results=#{count}")
    random_users = JSON.parse(
      random_user_url.read,
      symbolize_names: true
    )[:results]

    users = random_users.map do |random_user|
      user = User.new(
        name: "#{random_user[:name][:first]} #{random_user[:name][:last]}",
        email: random_user[:email],
        phone: random_user[:phone],
        password: random_user[:login][:password],
        body_mass_kg: ((Random.rand * 100) % 50) + 50,
      )

      random_user_image_url = URI(random_user[:picture][:medium])
      user.image = "data:image/jpeg;base64,#{Base64.encode64(random_user_image_url.open.read)}"
      user.save(validate: false)
      user
    end

    if users.count == 1
      users.first
    else
      users
    end
  end

  private

  def release_push_token
    User.where(push_token: push_token).where.not(id: id).update_all(push_token: nil)
  end
end
