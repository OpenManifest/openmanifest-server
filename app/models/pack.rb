# frozen_string_literal: true

# == Schema Information
#
# Table name: packs
#
#  id         :bigint           not null, primary key
#  rig_id     :bigint           not null
#  user_id    :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Pack < ApplicationRecord
  belongs_to :rig
  belongs_to :user
end
