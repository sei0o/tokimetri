module TasksHelper
  def when_label(task, today)
    if task.date && task.date >= today
      task.date.strftime("%-m/%-d %a")
    elsif task.week && task.week > today.beginning_of_week
      task.week.strftime("%-m/%-dの週")
    end
  end

  def day_label(date, today)
    [ { today => "今日", today + 1.day => "明日" }[date], date.strftime("%-m/%-d %a") ].compact.join(" ")
  end

  def week_label(week, today)
    week == today.next_week ? "来週" : week.strftime("%-m/%-dの週")
  end

  def move_options(today)
    [
      [ "inbox", "inbox" ], [ "今週", "week" ],
      *(today..today + 6.days).map { [ day_label(_1, today), _1.iso8601 ] },
      [ "来週", "next_week" ], [ "削除", "delete" ]
    ]
  end
end
