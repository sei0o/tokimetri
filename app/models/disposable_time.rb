# 起きている時間 = ルーティン + 天使の取り分（娯楽/だらだら） + 可処分。
# カテゴリは何をしたかの分類なので、可処分かどうかには天使の取り分にしか使わない
class DisposableTime
  ANGEL = "娯楽/だらだら".freeze

  def initialize(today, now)
    @today = today
    @usual = Page.usual(today)
    @page = Page.includes(:records).find_by(date: today)
    @fraction = @page&.awake_fraction(now, awake) || 0
  end

  # 過ぎた日に実際どうだったか。可処分はルーティンと天使の取り分の残り
  def self.actual(page)
    routines = PlannerList.routines.to_a
    activities = page.records.select(&:activity?)
    minutes = ->(records) { records.sum { _1.duration_minutes.to_i } }
    routine = minutes.(activities.select { |record| routines.any? { _1.matches?(record) } })
    angel = minutes.(activities.select { _1.category == ANGEL })
    { disposable: page.awake_minutes - routine - angel, awake: page.awake_minutes, routine:, angel: }
  end

  def known? = @usual.any?

  def awake = average(&:awake_minutes)

  def angel = average { _1.category_durations_minutes.to_h.fetch(ANGEL, 0) }

  def on(date) = parts(date)[:disposable]

  def parts(date)
    routine = minutes(routines(date))
    { disposable: awake - routine - angel, awake:, routine:, angel: }
  end

  def left_today = left_parts[:disposable]

  # 残り可処分の内訳。これから起きている時間から、まだ終わっていないルーティンと天使の取り分の残りを引く
  def left_parts
    awake_left = awake * (1 - @fraction)
    angel_left = angel * (1 - @fraction)
    routine = minutes(unfinished)
    { disposable: awake_left - routine - angel_left, awake: awake_left, routine:, angel: angel_left }
  end

  def left_week = left_today + (@today + 1.day..@today.end_of_week).sum { on(_1) }

  private

  def unfinished = routines(@today).reject { _1.finished_on?(@page) }

  def routines(date)
    (@routines ||= {})[date.wday] ||= PlannerList.on(date).to_a
  end

  def minutes(lists)
    @typical ||= {}
    lists.sum { @typical[_1.id] ||= _1.typical_minutes(@today) }
  end

  def average(&)
    return 0 if @usual.empty?

    @usual.sum(&) / @usual.size.to_f
  end
end
