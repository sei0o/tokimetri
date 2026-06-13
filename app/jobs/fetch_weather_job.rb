class FetchWeatherJob < ApplicationJob
  queue_as :default

  def perform
    WeatherService.prefetch
  end
end
