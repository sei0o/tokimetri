namespace :weather do
  desc "天気予報を取得してDBに保存する"
  task prefetch: :environment do
    data = WeatherService.prefetch
    if data
      puts "取得完了: #{Time.current.strftime('%H:%M')} / #{Setting.instance.weather_json&.length}bytes"
    else
      puts "取得失敗"
      exit 1
    end
  end
end
