class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  around_action :set_timezone

  private

  def set_timezone(&block)
    timezone = Setting.instance.timezone.presence || "Tokyo"
    Time.use_zone(timezone, &block)
  end
end
