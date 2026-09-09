class AddKindToRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :records, :kind, :string, default: "activity", null: false
  end
end
