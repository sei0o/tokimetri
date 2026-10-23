class AddRoutineToPlannerLists < ActiveRecord::Migration[8.0]
  def up
    add_column :planner_lists, :wdays, :string, default: "", null: false
    add_column :planner_lists, :period, :string
    add_column :planner_lists, :estimate_minutes, :integer
    change_column_null :planner_lists, :slug, true
    execute "UPDATE planner_lists SET wdays = '0123456' WHERE daily"
    remove_column :planner_lists, :daily
  end

  def down
    add_column :planner_lists, :daily, :boolean, default: false, null: false
    execute "UPDATE planner_lists SET daily = TRUE WHERE wdays <> ''"
    change_column_null :planner_lists, :slug, false
    remove_column :planner_lists, :estimate_minutes
    remove_column :planner_lists, :period
    remove_column :planner_lists, :wdays
  end
end
