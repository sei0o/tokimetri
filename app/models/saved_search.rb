class SavedSearch < ApplicationRecord
  validates :query, presence: true, uniqueness: true
end
