# frozen_string_literal: true

# == Schema Information
#
# Table name: rigs
#
#  id                :bigint           not null, primary key
#  make              :string
#  model             :string
#  serial            :string
#  pack_value        :integer
#  repack_expires_at :datetime
#  maintained_at     :datetime
#  user_id           :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  dropzone_id       :bigint
#  canopy_size       :integer
#  is_public         :boolean          default(FALSE)
#  rig_type          :integer
#  name              :string
#  packing_card      :text
#
require "test_helper"

class RigTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
