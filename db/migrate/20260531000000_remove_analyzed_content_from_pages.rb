class RemoveAnalyzedContentFromPages < ActiveRecord::Migration[8.0]
  def change
    remove_column :pages, :analyzed_content, :text
  end
end