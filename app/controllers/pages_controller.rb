class PagesController < ApplicationController
  before_action :parse_and_set_date, only: [ :show, :create, :update, :destroy, :analyze ]
  before_action :set_page, only: [ :show, :create, :update, :destroy, :analyze ]
  before_action :set_navigation_pages, only: [ :show ]

  def index
    @month = params[:month].present? ? Date.parse("#{params[:month]}-01") : Date.today.beginning_of_month
    @pages = Page.where(date: @month.beginning_of_month..@month.end_of_month)
  end

  def today
    now = Time.now.in_time_zone(Setting.instance.timezone.presence || "Tokyo")
    date = now.hour < 4 ? now.to_date - 1.day : now.to_date
    redirect_to date_path(date.strftime("%Y%m%d"))
  end

  def show
    @categories = Setting.instance.categories
    if turbo_frame_request? && params[:editable].present?
      render partial: "records_editable", locals: { page: @page }
      return
    end
    render :show
  end

  def view
    require "csv"
    @pages = Page.includes(:records).where.not(records: { id: nil }).distinct
    @categories = Setting.instance.categories
  end

  def search
    @saved_searches = SavedSearch.order(:query)
    @categories = Setting.instance.categories
    if params[:q].present?
      @records = Record.includes(:page)
                       .where("what LIKE ?", "%#{params[:q]}%")
                       .joins(:page)
                       .order("pages.date DESC, records.start_time ASC")

      # Calculate statistics
      durations = @records.map(&:duration_minutes).compact
      if durations.any?
        count = durations.size
        avg = durations.sum.to_f / count
        median = durations.sort[durations.size / 2]
        variance = durations.map { |d| (d - avg) ** 2 }.sum / count
        std_dev = Math.sqrt(variance)

        @stats = {
          count: count,
          avg: avg,
          median: median,
          std_dev: std_dev,
          min: durations.min,
          max: durations.max
        }
      end

      # Search from all the text content
      matching_pages = Page.where("content LIKE ?", "%#{params[:q]}%").order(date: :desc)
      # grep -C 1 のように前後 1 行を含めて表示用に整形
      @matches = matching_pages.map do |page|
        lines = page.content.to_s.lines
        match_indices = lines.each_index.select { |i| lines[i].include?(params[:q]) }

        ranges = match_indices.map { |i| [ [ i - 1, 0 ].max, [ i + 1, lines.length - 1 ].min ] }
        # example: [ [0, 2], [1, 3], [5, 7] ] -> [ [0, 3], [5, 7] ]
        merged_ranges = ranges.sort.each_with_object([]) do |(start_idx, end_idx), merged|
          if merged.empty? || start_idx > merged.last[1] + 1
            merged << [ start_idx, end_idx ]
          else
            merged.last[1] = [ merged.last[1], end_idx ].max
          end
        end

        matches = merged_ranges.map { |start_idx, end_idx| lines[start_idx..end_idx] }

        { page: page, matches: matches }
      end

      @query = params[:q]

      if @records.any?
        @heatmap_data = @records
          .group_by { |r| r.page.date }
          .transform_values { |recs| recs.sum { |r| (r.duration_minutes || 0).to_f / 60 } }
      end
    else
      @records = []
    end
  end

  def random
    @page = Page.where.not(content: [ nil, "" ]).order("RANDOM()").first
    if @page
      redirect_to date_path(@page.date.strftime("%Y%m%d"))
    else
      redirect_to today_path, alert: "内容があるページが見つかりませんでした"
    end
  end

  def create
    @page.assign_attributes(page_params)
    if @page.save
      redirect_to date_path(@date.strftime("%Y%m%d"))
    else
      set_navigation_pages
      render :show
    end
  end

  def update
    if @page.update(page_params)
      respond_to do |format|
        format.html { redirect_to date_path(@date.strftime("%Y%m%d")) }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update("editor-status", partial: "pages/save_status", locals: { status: "Saved" })
        }
      end
    else
      respond_to do |format|
        format.html {
          set_navigation_pages
          render :show, status: :unprocessable_entity
        }
        format.turbo_stream {
          render turbo_stream: turbo_stream.update("editor-status", partial: "pages/save_status", locals: { status: "Error saving" })
        }
      end
    end
  end

  def analyze
    @categories = Setting.instance.categories
    if @page.analyze_and_update
      redirect_to date_path(@date.strftime("%Y%m%d"))
    else
      set_navigation_pages
      render :show
    end
  end

  def analyze_all
    pages = Page.left_outer_joins(:records)
                .where.not(content: [ nil, "" ])
                .where(records: { id: nil })

    if pages.none?
      redirect_to review_path, notice: "未分析ページはありません"
      return
    end

    jsonl = pages.map { |p| p.to_batch_request.to_json }.join("\n")

    client = OpenAI::Client.new(api_key: Rails.application.credentials.openai.api_key)

    file = client.files.create(
      file: StringIO.new(jsonl),
      filename: "analyze_batch_#{Date.today}.jsonl",
      purpose: "batch"
    )

    batch = client.batches.create(
      input_file_id: file.id,
      endpoint: "/v1/chat/completions",
      completion_window: "24h"
    )

    Setting.instance.update!(batch_id: batch.id)

    redirect_to review_path, notice: "#{pages.count}件をバッチ送信しました（ID: #{batch.id}）。完了後に「バッチ結果を取得」してください。"
  end

  def check_batch
    setting = Setting.instance
    unless setting.batch_id.present?
      redirect_to review_path, alert: "バッチIDがありません"
      return
    end

    client = OpenAI::Client.new(api_key: Rails.application.credentials.openai.api_key)
    batch = client.batches.retrieve(setting.batch_id)

    unless batch.status == "completed"
      redirect_to review_path, notice: "バッチはまだ処理中です（status: #{batch.status}）"
      return
    end

    output = client.files.content(batch.output_file_id)
    count = 0

    output.each_line do |line|
      result = JSON.parse(line)
      next unless result["response"]["status_code"] == 200

      page_id = result["custom_id"].delete_prefix("page-").to_i
      page = Page.find_by(id: page_id)
      next unless page

      records_data = JSON.parse(result["response"]["body"]["choices"][0]["message"]["content"])["records"]
      page.apply_parsed_records(
        records_data.map { |r| OpenStruct.new(r) }
      )
      count += 1
    end

    setting.update!(batch_id: nil)
    redirect_to review_path, notice: "#{count}件のページを更新しました"
  end

  def review
    # 先週の記録を全部出す（月曜始まり）

    if params[:date].present?
      @startdate = Date.parse(params[:date])
    else
      @startdate = Date.today.beginning_of_week
    end
    @enddate = @startdate + 6.days

    @pages_thisweek = Page.where(date: @startdate..@enddate).order(:date)

    @categories = Setting.instance.categories

    @thisweek_avg = Page.calculate_category_averages(@pages_thisweek)
    @thisweek_wake_avg = Page.average_wake_time(@pages_thisweek)
    @thisweek_total = Page.calculate_category_total(@pages_thisweek)

    analyzing = session[:analyzing_week]
    if analyzing && analyzing["start"] == @startdate.to_s
      unanalyzed = @pages_thisweek.any? { |p| p.content.present? && p.records.empty? }
      if unanalyzed
        @analyzing = true
      else
        session.delete(:analyzing_week)
      end
    end

    render :review
  end

  def analyze_week
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    AnalyzeWeekJob.perform_later(start_date, end_date)
    session[:analyzing_week] = { "start" => start_date.to_s, "end" => end_date.to_s }

    redirect_to review_path(date: start_date), notice: "分析をバックグラウンドで開始しました。完了すると自動で更新されます"
  rescue Date::Error
    redirect_to review_path, alert: "日付の解析に失敗しました"
  end

  def destroy
    @page.destroy
    redirect_to pages_path
  end

  private

  def parse_and_set_date
    @date = Date.parse(params[:date])
  rescue Date::Error
    redirect_to today_path
  end

  def set_page
    @page = Page.find_by(date: @date) || Page.new(date: @date)
  end

  def set_navigation_pages
    return unless @date

    @yesterday = @date - 1.day
    @yesterday_page = Page.find_by(date: @yesterday)

    @tomorrow = @date + 1.day
    @tomorrow_page = Page.find_by(date: @tomorrow)

    @lastweek = @date - 7.days
    @lastweek_page = Page.find_by(date: @lastweek)

    @nextweek = @date + 7.days
    @nextweek_page = Page.find_by(date: @nextweek)
  end

  def page_params
    params.require(:page).permit(:date, :content, :note,
      records_attributes: [ :id, :start_time, :end_time, :what, :category, :_destroy ])
  end
end
