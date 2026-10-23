class PlannerItem < ApplicationRecord
  CONDITIONS = { "雨" => "rain" }.merge(PlannerList::WDAYS.zip(Date::DAYNAMES.map(&:downcase)).to_h).freeze

  belongs_to :planner_list

  enum :item_type, { task: "task", note: "note" }

  validates :content, presence: true

  before_create { self.position = planner_list.planner_items.maximum(:position).to_i + 1 if position.zero? }

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
