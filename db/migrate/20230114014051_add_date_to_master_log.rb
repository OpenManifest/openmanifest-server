class AddDateToMasterLog < ActiveRecord::Migration[7.0]
  def change
    add_column :master_logs, :date, :date
  end
end
