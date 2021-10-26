class AddRequestPublicationToDropzones < ActiveRecord::Migration[6.1]
  def change
    add_column :dropzones, :request_publication, :boolean, default: false
  end
end
