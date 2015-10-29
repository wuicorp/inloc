class CreateCellsFlags < ActiveRecord::Migration
  def change
    create_table :cells_flags do |t|
      t.integer :flag_id
      t.integer :cell_id
    end

    add_index :cells_flags, :cell_id
  end
end
