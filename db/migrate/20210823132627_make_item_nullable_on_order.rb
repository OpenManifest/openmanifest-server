# frozen_string_literal: true

class MakeItemNullableOnOrder < ActiveRecord::Migration[6.1]
  def change
    change_column_null :orders, :item_type, true
    change_column_null :orders, :item_id, true
  end
end
