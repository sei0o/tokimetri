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
    @categories = Setting.instance.categories
    @lists = PlannerList.ordered
    @candidates = PlannerList.candidates(current_date)
  end

  def today
    @weather = WeatherService.summary
    @planner = TodayPlanner.new
    @sections = @planner.sections
  end
end
