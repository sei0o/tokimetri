class AddNoteToPlannerLists < ActiveRecord::Migration[8.0]
  def change
    add_column :planner_lists, :note, :text
  end
end
