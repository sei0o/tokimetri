class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.text :prompt

      t.timestamps
    end
  end
end
