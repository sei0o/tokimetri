class AnalyzeWeekJob < ApplicationJob
  queue_as :default

  def perform(start_date, end_date)
    Page.where(date: start_date..end_date).order(:date).each do |page|
      page.analyze_and_update if page.content.present?
    end
  end
end
