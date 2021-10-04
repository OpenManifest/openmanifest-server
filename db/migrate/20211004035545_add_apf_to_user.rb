class AddApfToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :apf_number, :string
  end
end
