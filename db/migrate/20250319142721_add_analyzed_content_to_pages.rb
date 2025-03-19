class AddAnalyzedContentToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :analyzed_content, :text
  end
end
