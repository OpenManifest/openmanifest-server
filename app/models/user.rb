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
#  exit_weight            :float
#  license_id             :bigint
#  tokens                 :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  push_token             :string
#  unconfirmed_email      :string
#  time_zone              :string           default("Australia/Brisbane")
#  jump_count             :integer          default(0), not null
#  dropzone_count         :integer          default(0), not null
#  plane_count            :integer          default(0), not null
#
class User < ApplicationRecord
  include CloudinaryHelper

  # Include default devise modules.
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :trackable, :validatable, :confirmable
  include Discard::Model
  include GraphqlDevise::Concerns::Model
  include DeviseTokenAuth::Concerns::User

  # Simple role structure for global permissions
  # Most users will have 'user', and only users with
  # permissions to manage on an organizational level
  # have anything else
  enum moderation_role: [
    :user,
    :support,
    :moderator,
    :administrator
  ]

  after_create do
    Appsignal.set_gauge("users.count", User.count)
  end

  mount_base64_uploader :image, AvatarUploader, file_name: -> (u) { "avatar-#{u.id}-#{Time.current.to_i}.png" }

  has_many :rigs, -> { kept }
  has_many :packs
  has_many :dropzone_users, -> { kept }
  has_many :dropzones, -> { kept }, through: :dropzone_users
  has_many :slots, through: :dropzone_users
  has_many :loads, -> { kept }, through: :slots
  has_many :user_roles, through: :dropzone_users

  belongs_to :license, optional: true

  has_many :user_federations
  has_many :licenses, through: :user_federations
  has_many :user_federation_qualifications, through: :user_federations
  has_many :qualifications, through: :user_federation_qualifications


  def can?(permission_name, dropzone_id:)
    if dz_user = dropzone_users.find_by(dropzone_id: dropzone_id)
      dz_user.can?(permission_name)
    else
      false
    end
  end

  def self.create_fake(count: 1)
    random_user_url = URI("https://randomuser.me/api/?results=#{count}")
    random_users = JSON.parse(
      random_user_url.open.read,
      symbolize_names: true
    )[:results]

    users = random_users.map do |random_user|
      user = User.new(
        name: "#{random_user[:name][:first]} #{random_user[:name][:last]}",
        email: random_user[:email],
        phone: random_user[:phone],
        password: random_user[:login][:password],
        exit_weight: ((Random.rand * 100) % 50) + 50,
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
end
