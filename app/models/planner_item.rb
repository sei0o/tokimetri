class PlannerItem < ApplicationRecord
  belongs_to :planner_list

  enum :item_type, { task: "task", note: "note" }

  validates :content, presence: true

  def visible?(context)
    case condition&.to_sym
    when nil   then true
    when :rain then context[:rain]
    else            context[:date].public_send("#{condition}?")
    end
  rescue NoMethodError
    true
  end
end
