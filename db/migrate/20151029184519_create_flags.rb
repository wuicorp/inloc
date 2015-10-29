class CreateFlags < ActiveRecord::Migration
  def change
    create_table :flags do |t|
      t.integer :application_id
      t.decimal :longitude
      t.decimal :latitude
      t.integer :radius
    end

    add_index :flags, :application_id
  end
end
