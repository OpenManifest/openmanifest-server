# frozen_string_literal: true

# == Schema Information
#
# Table name: packs
#
#  id         :integer          not null, primary key
#  rig_id     :integer          not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Pack < ApplicationRecord
  belongs_to :rig
  belongs_to :user
end
