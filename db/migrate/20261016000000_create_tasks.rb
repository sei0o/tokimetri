class CreateTasks < ActiveRecord::Migration[8.0]
  def change
    create_table :tasks do |t|
      t.string :content, null: false
      t.date :date
      t.date :week
      t.integer :position, default: 0, null: false
      t.timestamps
    end
    add_index :tasks, :date
    add_index :tasks, :week
  end
end
