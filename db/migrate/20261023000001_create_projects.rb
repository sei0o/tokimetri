class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.string :category
      t.string :query
      t.text :note
      t.timestamps
    end

    add_reference :tasks, :project, foreign_key: true
  end
end
