class PlannerList < ApplicationRecord
  has_many :planner_items, -> { order(:position) }, dependent: :destroy, inverse_of: :planner_list
end