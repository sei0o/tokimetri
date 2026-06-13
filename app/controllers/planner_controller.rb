class PlannerController < ApplicationController
  def index; end
  def clean; end
  def meet; end
  def bath; end
  def meal; end

  def weather
    summary = WeatherService.summary
    render json: summary
  end

  def everyday
    @context = { date: Date.current, rain: false }
    @lists = %w[morning leave_home evening].filter_map do |slug|
      list = PlannerList.find_by(slug: slug)
      next unless list
      items = list.planner_items.select { |item| item.visible?(@context) }
      { list: list, items: items }
    end
    @garbage = GarbageSource.new(date: @context[:date])
  end

  def today
    @weather = WeatherService.summary
    @planner = TodayPlanner.new
    @sections = @planner.sections
  end
end
