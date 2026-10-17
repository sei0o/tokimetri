module TasksHelper
  def when_label(task, today)
    if task.date && task.date >= today
      task.date.strftime("%-m/%-d %a")
    elsif task.week && task.week > today.beginning_of_week
      task.week.strftime("%-m/%-dの週")
    end
  end
end
