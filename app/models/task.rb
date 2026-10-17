# どこにあるかは date と week で決まる。
# 終わらなかった日のタスクは今週に、終わらなかった週のタスクは inbox に戻って見える
class Task < ApplicationRecord
  validates :content, presence: true

  before_save { self.week = date.beginning_of_week if date }
  before_create { self.category = Record.guess_category(content) if category.blank? }

  scope :ordered, -> { order(:position, :id) }
  scope :on, ->(date) { where(date: date).ordered }
  scope :left_in_week, ->(date) { where(week: date.beginning_of_week).where("date IS NULL OR date < ?", date).ordered }
  scope :inbox, ->(date) { where("week IS NULL OR week < ?", date.beginning_of_week).ordered }
  scope :planned, ->(date) { where(week: date.beginning_of_week..).order(:week, :date, :position, :id) }

  def self.next_position = maximum(:position).to_i + 1

  def move(to, today)
    case to
    when "today"    then update(date: today)
    when "tomorrow" then update(date: today + 1.day)
    when "week"     then update(date: nil, week: today.beginning_of_week)
    when "inbox"    then update(date: nil, week: nil)
    when "delete"   then destroy
    end
  end
end
