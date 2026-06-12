class WeatherService
  BASE_URL = "https://api.open-meteo.com/v1/forecast"
  LAT = 35.732
  LON = 139.74
  CACHE_KEY = "weather_data"
  CACHE_TTL = 30.minutes

  def self.rain?(hours_ahead: 12)
    new.rain?(hours_ahead: hours_ahead)
  end

  def self.summary
    new.summary
  end

  def rain?(hours_ahead: 12)
    data = cached_fetch
    return false unless data

    hours = data.dig("hourly", "time") || []
    precip = data.dig("hourly", "precipitation") || []
    now = Time.current
    limit = now + hours_ahead.hours

    hours.each_with_index.any? do |time_str, i|
      t = Time.parse(time_str)
      t > now && t <= limit && (precip[i] || 0) > 0
    end
  rescue StandardError
    false
  end

  def summary
    data = cached_fetch
    return nil unless data

    temps = data.dig("hourly", "temperature_2m") || []
    valid = temps.compact
    {
      max_temp: valid.max&.round,
      min_temp: valid.min&.round,
      rain: rain_from(data)
    }
  rescue StandardError
    nil
  end

  private

  def cached_fetch
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) { fetch }
  end

  def fetch
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(
      latitude: LAT,
      longitude: LON,
      hourly: "precipitation,temperature_2m",
      forecast_days: 1,
      timezone: "Asia/Tokyo"
    )
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)
    JSON.parse(response.body)
  rescue StandardError
    nil
  end

  def rain_from(data, hours_ahead: 12)
    hours = data.dig("hourly", "time") || []
    precip = data.dig("hourly", "precipitation") || []
    now = Time.current
    limit = now + hours_ahead.hours

    hours.each_with_index.any? do |time_str, i|
      t = Time.parse(time_str)
      t > now && t <= limit && (precip[i] || 0) > 0
    end
  rescue StandardError
    false
  end
end
