class CreateCells < ActiveRecord::Migration
  def change
    create_table :cells do |t|
      t.decimal :longitude
      t.decimal :latitude
    end

    add_index :cells, [:longitude, :latitude]
  end
end
