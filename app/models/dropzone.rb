# == Schema Information
#
# Table name: dropzones
#
#  id            :integer          not null, primary key
#  name          :string
#  federation_id :integer
#  lat           :float
#  lng           :float
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Dropzone < ApplicationRecord

  has_many :dropzone_users
  has_many :users, through: :dropzone_users
  
  has_many :planes
  has_many :loads, through: :planes
  has_many :load_masters, through: :loads
  has_many :ticket_types

  belongs_to :federation
  
  has_one_base64_attached :banner


end
