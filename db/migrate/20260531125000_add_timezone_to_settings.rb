class AddTimezoneToSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :settings, :timezone, :string, default: "Tokyo"
  end
end
