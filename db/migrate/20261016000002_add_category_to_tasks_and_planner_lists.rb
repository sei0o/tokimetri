class AddCategoryToTasksAndPlannerLists < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :category, :string
    add_column :planner_lists, :category, :string
    up_only do
      execute "UPDATE planner_lists SET category = '生活' WHERE slug IN ('morning', 'evening')"
    end
  end
end
