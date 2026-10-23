class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_date

  private

  def local_now = Time.now.in_time_zone(Setting.instance.timezone.presence || "Tokyo")

  # 朝4時までは前の日として扱う
  def current_date
    now = local_now
    now.hour < 4 ? now.to_date - 1.day : now.to_date
  end

  # 記録の時刻は現地の時計の数字を UTC として持っているので、いまもそれに揃える
  def current_time = Time.current + local_now.utc_offset
end
