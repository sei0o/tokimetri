require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    @today = Date.new(2026, 10, 16)
  end

  test "日を決めると週も決まる" do
    task = Task.create!(content: "戸籍", date: @today)
    assert_equal Date.new(2026, 10, 12), task.week
  end

  test "終わらなかった日のタスクは今週に、終わらなかった週のタスクは inbox に戻る" do
    yesterday = Task.create!(content: "保険書類", date: @today - 1.day)
    last_week = Task.create!(content: "セブン銀行", date: @today - 7.days)
    sometime = Task.create!(content: "chocozap", week: @today.beginning_of_week)
    today = Task.create!(content: "輪講", date: @today)

    assert_equal [ today ], Task.on(@today).to_a
    assert_equal [ yesterday, sometime ], Task.left_in_week(@today).to_a
    assert_equal [ last_week ], Task.inbox(@today).to_a
  end

  test "移動" do
    task = Task.create!(content: "青いカバ")

    task.move("tomorrow", @today)
    assert_equal @today + 1.day, task.date

    task.move("week", @today)
    assert_nil task.date
    assert_equal @today.beginning_of_week, task.week

    task.move("inbox", @today)
    assert_nil task.week

    task.move("2026-10-21", @today)
    assert_equal [ Date.new(2026, 10, 21), Date.new(2026, 10, 19) ], [ task.date, task.week ]

    task.move("next_week", @today)
    assert_equal [ nil, Date.new(2026, 10, 19) ], [ task.date, task.week ]
  end

  test "見積もりは「1:30」でも「90」でも 90 分" do
    assert_equal [ 90, 90, nil, nil ], [ "1:30", "90", "", "そのうち" ].map { Task.new(estimate_minutes: _1).estimate_minutes }
  end
end
