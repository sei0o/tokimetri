class TodayPlanner
  def initialize(date: Date.current)
    @date = date
    @context = { date: @date, rain: WeatherService.rain? }
  end

  def sections
    [
      { title: "朝", items: list_items("morning") + garbage_items(:today) },
      { title: "出かける", items: list_items("leave_home") },
      { title: "夜", items: list_items("evening") + garbage_items(:tomorrow) },
    ].reject { |s| s[:items].empty? }
  end

  private

  def list_items(slug)
    list = PlannerList.find_by(slug: slug)
    return [] unless list
    list.planner_items.select { |item| item.visible?(@context) }
  end

  def garbage_items(timing)
    GarbageSource.new(date: @date).tasks.then do |tasks|
      tasks = tasks.select { |t| timing == :tomorrow ? t[:source] == :garbage_tomorrow : t[:source] == :garbage }
      tasks.map do |t|
        PlannerItem.new(content: t[:content], item_type: "task", planner_list_id: nil)
      end
    end
  end
end
