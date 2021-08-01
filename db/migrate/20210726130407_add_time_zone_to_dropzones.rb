# frozen_string_literal: true

class AddTimeZoneToDropzones < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :time_zone, :string, default: "Australia/Brisbane"
  end
end
