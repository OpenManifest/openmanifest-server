# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  name            :string
#  email           :string
#  phone           :string
#  password        :string
#  password_digest :string
#  exit_weight     :float
#  license_id      :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class User < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :trackable, :validatable
  include GraphqlDevise::Concerns::Model
  include DeviseTokenAuth::Concerns::User


  has_many :rigs
  has_many :packs
  has_many :dropzone_users
  has_many :dropzones, through: :dropzone_users
  has_many :slots
  has_many :loads, through: :slots
  has_many :roles, through: :dropzone_users
  
  belongs_to :license, optional: true
  has_many :licensed_jump_types, through: :license
  has_many :jump_types, through: :licensed_jump_types
end
