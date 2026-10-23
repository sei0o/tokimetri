require "test_helper"

class DisposableTimeTest < ActiveSupport::TestCase
  def day(date, *records)
    Page.create!(date: date).tap do |page|
      records.each do |start, finish, category, what|
        page.records.create!(start_time: Time.zone.parse("#{date} #{start}"), end_time: finish && Time.zone.parse("#{date} #{finish}"),
                             category: category, what: what)
      end
    end
  end

  setup do
    # いつもは起きている 16 時間のうち、娯楽 2 時間
    day("2026-10-12", [ "00:00", "08:00", "睡眠" ], [ "08:00", "11:00", "生活" ], [ "11:00", "22:00", "研究" ], [ "22:00", "24:00", "娯楽/だらだら" ])
    PlannerList.create!(title: "朝の準備", wdays: "0123456", category: "生活", estimate_minutes: 60)
    PlannerList.create!(title: "講義", wdays: "4", category: "講義", estimate_minutes: 180)
  end

  test "その日の可処分は、起きている時間からその曜日のルーティンと天使の取り分を引いたもの" do
    time = DisposableTime.new(Date.new(2026, 10, 21), Time.zone.parse("2026-10-21 16:00"))

    assert_equal 14 * 60 - 60, time.on(Date.new(2026, 10, 21))
    assert_equal 14 * 60 - 60 - 180, time.on(Date.new(2026, 10, 22))
  end

  test "今日の残りはまだやっていないルーティンだけを引き、今週の残りは明日からの日を足す" do
    day("2026-10-21", [ "00:00", "08:00", "睡眠" ], [ "08:00", "09:00", "生活", "朝の準備" ], [ "09:00", nil, "研究" ])
    time = DisposableTime.new(Date.new(2026, 10, 21), Time.zone.parse("2026-10-21 16:00"))

    assert_equal 14 * 60 * 0.5, time.left_today
    assert_equal 14 * 60 * 0.5 + (14 * 60 - 60) * 4 - 180, time.left_week
  end

  test "過ぎた日に実際に使えた時間" do
    page = day("2026-10-20", [ "00:00", "08:00", "睡眠" ], [ "08:00", "09:30", "生活", "朝の準備" ], [ "09:30", "10:00", "生活", "洗濯" ],
               [ "10:00", "22:00", "研究" ], [ "22:00", "24:00", "娯楽/だらだら" ])

    assert_equal({ disposable: 16 * 60 - 90 - 120, awake: 16 * 60, routine: 90, angel: 120 }, DisposableTime.actual(page))
  end
end
