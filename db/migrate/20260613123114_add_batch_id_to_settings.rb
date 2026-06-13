class AddBatchIdToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :batch_id, :string
  end
end
