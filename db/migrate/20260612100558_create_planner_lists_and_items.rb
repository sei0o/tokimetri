class CreatePlannerListsAndItems < ActiveRecord::Migration[8.0]
  def change
    create_table :planner_lists do |t|
      t.string :slug, null: false
      t.string :title, null: false
      t.timestamps
    end
    add_index :planner_lists, :slug, unique: true

    create_table :planner_items do |t|
      t.references :planner_list, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.string :item_type, null: false, default: "task"
      t.string :content, null: false, default: ""
      t.integer :duration_seconds
      t.string :condition
      t.timestamps
    end
    add_index :planner_items, [ :planner_list_id, :position ]
  end
end
