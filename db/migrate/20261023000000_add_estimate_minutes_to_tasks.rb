class AddEstimateMinutesToTasks < ActiveRecord::Migration[8.0]
  def change
    add_column :tasks, :estimate_minutes, :integer
  end
end
