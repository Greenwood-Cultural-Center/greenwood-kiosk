class CreateParcels < ActiveRecord::Migration[7.2]
  def change
    create_table :parcels do |t|
      t.json :boundaries
      t.string :name
      t.text :notes

      t.timestamps
    end
  end
end
