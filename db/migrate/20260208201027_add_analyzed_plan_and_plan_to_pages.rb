class AddAnalyzedPlanAndPlanToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :analyzed_plan, :text
    add_column :pages, :plan, :text
  end
end
