class AddParcelToBuildings < ActiveRecord::Migration[7.2]
  def change
    add_reference :buildings, :parcel, null: true, foreign_key: true
  end
end
