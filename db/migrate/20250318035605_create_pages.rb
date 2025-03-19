class CreatePages < ActiveRecord::Migration[7.2]
  def change
    create_table :pages do |t|
      t.date :date
      t.text :content

      t.timestamps
    end
  end
end
