require "test_helper"

class PageTest < ActiveSupport::TestCase
  def page_with(date, *records)
    Page.create!(date: date).tap do |page|
      records.each do |start, finish, category|
        page.records.create!(start_time: Time.zone.parse("#{date} #{start}"),
                             end_time: finish && Time.zone.parse("#{date} #{finish}"), category: category)
      end
    end
  end

  test "weekly_pace compares this week so far with usual days" do
    page_with("2026-10-05", [ "00:00", "08:00", "睡眠" ], [ "08:00", "12:00", "研究" ], [ "12:00", "20:00", "生活" ])
    page_with("2026-10-06", [ "08:00", "10:00", "研究" ])
    page_with("2026-10-12", [ "08:00", "14:00", "研究" ], [ "14:00", "20:00", "生活" ])
    page_with("2026-10-13", [ "00:00", "08:00", "睡眠" ], [ "08:00", "12:00", "趣味" ], [ "12:00", nil, "研究" ])

    pace = Page.weekly_pace(Date.new(2026, 10, 13), Time.zone.parse("2026-10-13 14:00"))

    assert_equal [ 480, 480 - 240 * 1.5, 240 * 7 ], pace["研究"]
    assert_equal [ 360, 360 - 480 * 1.5, 480 * 7 ], pace["生活"]
    assert_equal [ 240, 240, 0 ], pace["趣味"]
    assert_equal [ 0, 0, 0 ], pace["娯楽/だらだら"]
  end

  test "weekly_pace is empty without usual days" do
    assert_empty Page.weekly_pace(Date.new(2026, 10, 13), Time.zone.parse("2026-10-13 14:00"))
  end

  test "翌日に書いた起床だけの睡眠は前日の最後から始まる" do
    today = page_with("2026-10-06", [ "20:00", "23:20", "娯楽/だらだら" ])
    tomorrow = Page.create!(date: "2026-10-07")
    sleep = tomorrow.records.create!(end_time: Time.zone.parse("2026-10-07 07:30"), what: "睡眠", category: "睡眠")

    tomorrow.add_missing_sleep_before!(Date.new(2026, 10, 7))
    tomorrow.reconcile_sleep_boundaries!

    assert_equal Time.zone.parse("2026-10-06 23:20"), sleep.reload.start_time
    assert_equal 1, today.records.count
  end

  test "前日に書き足したら睡眠の始まりもずれる" do
    today = page_with("2026-10-06", [ "20:00", "21:00", "生活" ])
    tomorrow = Page.create!(date: "2026-10-07")
    sleep = tomorrow.records.create!(end_time: Time.zone.parse("2026-10-07 07:30"), category: "睡眠")
    tomorrow.reconcile_sleep_boundaries!

    today.records.create!(start_time: Time.zone.parse("2026-10-06 21:00"), end_time: Time.zone.parse("2026-10-07 00:40"), category: "娯楽/だらだら")
    today.reconcile_sleep_boundaries!

    assert_equal Time.zone.parse("2026-10-07 00:40"), sleep.reload.start_time
  end

  test "自分で書いた入眠時刻は動かさない" do
    page_with("2026-10-06", [ "20:00", "23:20", "生活" ])
    tomorrow = Page.create!(date: "2026-10-07")
    sleep = tomorrow.records.create!(start_time: Time.zone.parse("2026-10-07 00:10"), end_time: Time.zone.parse("2026-10-07 07:30"), category: "睡眠")

    tomorrow.reconcile_sleep_boundaries!

    assert_equal Time.zone.parse("2026-10-07 00:10"), sleep.reload.start_time
  end
end
