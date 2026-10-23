require "test_helper"

class PlannerListTest < ActiveSupport::TestCase
  def day(date, *records)
    Page.create!(date: date).tap do |page|
      records.each do |what, minutes|
        start = Time.zone.parse("#{date} 08:00")
        page.records.create!(what: what, category: "趣味", start_time: start, end_time: minutes && start + minutes.minutes)
      end
    end
  end

  test "曜日で今日のルーティンを選び、時間帯順に並べる" do
    night = PlannerList.create!(title: "夜の支度", wdays: "0123456", period: "夜")
    morning = PlannerList.create!(title: "朝の準備", wdays: "0123456", period: "朝")
    PlannerList.create!(title: "掃除", wdays: "6", period: "朝")
    PlannerList.create!(title: "メモ")

    assert_equal [ morning, night ], PlannerList.on(Date.new(2026, 10, 22)).to_a
  end

  test "いつもの長さは最近やった日の中央値。なければ見積もり" do
    list = PlannerList.create!(title: "朝の準備", wdays: "0123456", category: "生活", estimate_minutes: 20)
    assert_equal 20, list.typical_minutes(Date.new(2026, 10, 23))

    day("2026-10-20", [ "朝の準備", 30 ], [ "朝ごはん", 10 ])
    day("2026-10-21", [ "朝の準備", 50 ])
    day("2026-10-22", [ "朝の準備", 40 ])

    assert_equal 40, list.typical_minutes(Date.new(2026, 10, 23))
  end

  test "タイトルと完全に一致する行だけがルーティンのもので、カテゴリが揃う" do
    PlannerList.create!(title: "夜", wdays: "0123456", category: "生活")
    page = day("2026-10-20", [ "夜", 30 ], [ "夜更かし", 60 ])

    assert_equal [ "生活", "趣味" ], page.records.map(&:category)
  end

  test "何度も出てくるのにルーティンでない行が候補になる" do
    PlannerList.create!(title: "朝の準備", wdays: "0123456")
    (0..4).each { |i| day((Date.new(2026, 10, 5) + (i * 7).days).to_s, [ "シャワー", 20 + i ], [ "朝の準備", 30 ]) }
    day("2026-10-06", [ "シャワー", 30 ])
    day("2026-10-07", [ "ゲーム", 60 ])

    candidates = PlannerList.candidates(Date.new(2026, 11, 3))

    assert_equal [ "シャワー" ], candidates.map { _1[:title] }
    assert_equal({ title: "シャワー", category: "趣味", days: 5, estimate_minutes: 23, wdays: [ 1 ] }, candidates.first)
  end
end
