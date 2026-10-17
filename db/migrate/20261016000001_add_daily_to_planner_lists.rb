class AddDailyToPlannerLists < ActiveRecord::Migration[8.0]
  def change
    add_column :planner_lists, :daily, :boolean, default: false, null: false
    up_only do
      execute "UPDATE planner_lists SET daily = TRUE WHERE slug IN ('morning', 'leave_home', 'evening')"
    end
  end
end
