module PagesHelper
  def activities_by_date(pages)
    ret = {}
    pages.each do |page|
      ret.merge!(activities_by_date_for_page(page)) do |date, old_val, new_val|
        old_val + new_val
      end
    end

    ret.sort_by { |date, activities| date }
  end

  def activities_by_date_for_page(page)
    return {} unless page.records.any?

    ret = {}

    page.records.each do |record|
      next if record.start_time.nil? || record.end_time.nil?

      start_match = record.start_time.strftime("%Y-%m-%d %H:%M").match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
      end_match = record.end_time.strftime("%Y-%m-%d %H:%M").match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
      next unless start_match && end_match

      start_date = "#{start_match[1]}-#{start_match[2]}-#{start_match[3]}"
      end_date = "#{end_match[1]}-#{end_match[2]}-#{end_match[3]}"

      # Add to start date's activities
      ret[start_date] ||= []
      ret[start_date] << record

      # If overnight, also add to end date's activities
      if start_date != end_date
        ret[end_date] ||= []
        ret[end_date] << record
      end
    end

    ret
  end

  def calculate_hday_slot_position(record, date)
    start_match = record.start_time.strftime("%Y-%m-%d %H:%M").match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
    end_match = record.end_time.strftime("%Y-%m-%d %H:%M").match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)

    start_date = "#{start_match[1]}-#{start_match[2]}-#{start_match[3]}"
    end_date = "#{end_match[1]}-#{end_match[2]}-#{end_match[3]}"

    start_hour = start_match[4].to_i
    start_min = start_match[5].to_i
    end_hour = end_match[4].to_i
    end_min = end_match[5].to_i

    # Calculate position and width based on current date
    if start_date == date && end_date == date
      # Activity entirely within this date
      start_time_decimal = start_hour + (start_min / 60.0)
      end_time_decimal = end_hour + (end_min / 60.0)
      left_pos = start_time_decimal / 24.0
      width = (end_time_decimal - start_time_decimal) / 24.0
    elsif start_date != date && end_date == date
      # Activity started on previous day, ends today
      left_pos = 0
      end_time_decimal = end_hour + (end_min / 60.0)
      width = end_time_decimal / 24.0
    elsif start_date == date && end_date != date
      # Activity starts today, ends on future day
      start_time_decimal = start_hour + (start_min / 60.0)
      left_pos = start_time_decimal / 24.0
      width = (24.0 - start_time_decimal) / 24.0
    else
      # This shouldn't happen with our grouping, but just in case
      return nil
    end

    {
      left_pos: left_pos,
      width: width,
      category: record.category,
      title: "#{record.what} (#{record.start_time} - #{record.end_time})"
    }
  end

  # ページの日付を基準に「25:30」のような 24 時超え表記へ直す
  def extended_time(datetime, page_date)
    return "" unless datetime

    hours = (datetime.to_date - page_date).to_i * 24 + datetime.hour
    "#{hours}:#{datetime.strftime("%M")}"
  end

  def minutes_to_hm(minutes)
    sign = minutes.negative? ? "-" : ""
    hours = (minutes.abs / 60).floor
    mins = (minutes.abs % 60).round
    sprintf("%s%d:%02d", sign, hours, mins)
  end

  # 「1:30」でも「90」でも入れられる長さの欄
  def minutes_field_tag(name, minutes, **options)
    text_field_tag name, (minutes_to_hm(minutes) if minutes), placeholder: "0:30", size: 5, **options
  end

  # ↻ はルーティン、色つきは天使の取り分
  def disposable_formula(parts)
    angel = tag.span(minutes_to_hm(parts[:angel]), style: "color: #{@categories[DisposableTime::ANGEL]}", title: DisposableTime::ANGEL)
    breakdown = tag.span(safe_join([ "= #{minutes_to_hm(parts[:awake])} − ↻ #{minutes_to_hm(parts[:routine])} − ", angel ]), class: "formula")
    safe_join([ minutes_to_hm(parts[:disposable]), breakdown ], " ")
  end

  # 選んだときに行の色を変えられるよう、淡い色を持たせる
  def category_options
    @categories.map { |category, color| [ category, category, { data: { color: hex_to_pastel(color) } } ] }
  end

  def hex_to_pastel(hex)
    return "#fff" if hex.nil?

    hex = hex.gsub("#", "")

    if hex.length == 3
      r = hex[0].to_i(16) * 17
      g = hex[1].to_i(16) * 17
      b = hex[2].to_i(16) * 17
    elsif hex.length == 6
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)
    else
      return "#fff"
    end

    # パステルカラーにする（元の色と白を7:3で混ぜる）
    lightness = 0.7
    r = (r + (255 - r) * lightness).round
    g = (g + (255 - g) * lightness).round
    b = (b + (255 - b) * lightness).round

    "#%02x%02x%02x" % [ r, g, b ]
  end
end
