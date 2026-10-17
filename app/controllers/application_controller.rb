class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_date

  private

  # 朝4時までは前の日として扱う
  def current_date
    now = Time.now.in_time_zone(Setting.instance.timezone.presence || "Tokyo")
    now.hour < 4 ? now.to_date - 1.day : now.to_date
  end
end
