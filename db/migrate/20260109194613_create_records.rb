class CreateRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :records do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.string :what
      t.string :category
      t.references :page, null: false, foreign_key: true 

      t.timestamps
    end
  end
end
