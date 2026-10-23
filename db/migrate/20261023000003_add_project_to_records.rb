class AddProjectToRecords < ActiveRecord::Migration[8.0]
  def change
    add_reference :records, :project, foreign_key: true
  end
end
