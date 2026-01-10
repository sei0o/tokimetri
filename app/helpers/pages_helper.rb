module PagesHelper
  def activities_by_date pages
    ret = {}
    pages.each do |page|
      ret.merge!(activities_by_date_for_page(page)) do |date, old_val, new_val|
        old_val + new_val
      end
    end

    ret.sort_by { |date, activities| date }
  end

  def activities_by_date_for_page(page)
    return {} unless page.analyzed_content.present?
    
    ret = {}
    
    CSV.parse(page.analyzed_content).each do |line|
      next if line[0] == 'start' || line[0] == '_' || line[1] == '_'
      
      start_match = line[0].match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
      end_match = line[1].match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
      next unless start_match && end_match
      
      start_date = "#{start_match[1]}-#{start_match[2]}-#{start_match[3]}"
      end_date = "#{end_match[1]}-#{end_match[2]}-#{end_match[3]}"
      
      # Add to start date's activities
      ret[start_date] ||= []
      ret[start_date] << line
      
      # If overnight, also add to end date's activities
      if start_date != end_date
        ret[end_date] ||= []
        ret[end_date] << line
      end
    end
    
    ret
  end
  
  def calculate_hday_slot_position(line, date)
    start_match = line[0].match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
    end_match = line[1].match(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/)
    
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
      category: line[3].strip,
      title: "#{line[2]} (#{line[0]} - #{line[1]})"
    }
  end

  def minutes_to_hm minutes
    hours = (minutes / 60).floor
    mins = (minutes % 60).round
    sprintf("%d:%02d", hours, mins)
  end

  def hex_to_pastel(hex)
    return "#fff" if hex.nil?
    
    hex = hex.gsub('#', '')
    
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
    
    "#%02x%02x%02x" % [r, g, b]
  end
end
