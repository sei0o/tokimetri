class PlannerList < ApplicationRecord
  PERIODS = %w[朝 昼 夜].freeze
  WDAYS = %w[日 月 火 水 木 金 土].freeze

  attribute :estimate_minutes, MinutesType.new

  has_many :planner_items, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :planner_list
  accepts_nested_attributes_for :planner_items, reject_if: ->(attrs) { attrs[:id].blank? && attrs[:content].blank? }

  validates :title, presence: true

  before_validation { planner_items.each { _1.mark_for_destruction if _1.content.blank? } }

  scope :ordered, -> { in_order_of(:period, PERIODS, filter: false).order(:id) }
  scope :routines, -> { where.not(wdays: "") }
  scope :on, ->(date) { where("wdays LIKE ?", "%#{date.wday}%").ordered }

  def wdays=(value)
    super(Array(value).join)
  end

  def wdays_label = wdays.chars.map { WDAYS[_1.to_i] }.join

  # 「始める」で書いた行はタイトルそのままになる。「朝」が「朝ごはん」に当たらないよう完全一致で見る
  def matches?(record) = record.activity? && record.what == title

  def records = Record.activities.joins(:page).where(what: title)

  # 最近8週間で、やった日ごとの合計の中央値。まだやっていなければ見積もり
  def typical_minutes(today)
    totals = records.where(pages: { date: (today - 8.weeks)...today })
                    .group_by(&:page_id).values.map { |day| day.sum { _1.duration_minutes.to_i } }
    totals.empty? ? estimate_minutes.to_i : totals.sort[totals.size / 2]
  end

  # 最近4週間のうち4日以上あったのに、どのルーティンにも当たらない行。
  # 同じ曜日に2回以上あった曜日を、ルーティンにするときの曜日にする
  def self.candidates(today)
    lists = all.to_a
    Record.activities.includes(:page).where(pages: { date: (today - 4.weeks)...today })
          .where.not(category: [ "睡眠", DisposableTime::ANGEL ]).where.not(what: [ nil, "" ])
          .reject { |record| lists.any? { _1.matches?(record) } }
          .group_by(&:what)
          .map { |what, records| candidate(what, records) }
          .select { _1[:days] >= 4 }
          .sort_by { -_1[:days] }
  end

  def self.candidate(what, records)
    dates = records.map { _1.page.date }.uniq
    totals = records.group_by(&:page_id).values.map { |day| day.sum { _1.duration_minutes.to_i } }.sort
    {
      title: what,
      category: records.map(&:category).tally.max_by(&:last)&.first,
      days: dates.size,
      estimate_minutes: totals[totals.size / 2],
      wdays: dates.map(&:wday).tally.select { _2 >= 2 }.keys.sort
    }
  end

  private_class_method :candidate

  def records_on(page)
    page ? page.records.select { matches?(_1) } : []
  end
end
