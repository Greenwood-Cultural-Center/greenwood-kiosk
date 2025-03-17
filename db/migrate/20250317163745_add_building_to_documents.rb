class AddBuildingToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_reference :documents, :building, null: true, foreign_key: true
  end
end
