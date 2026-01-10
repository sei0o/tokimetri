# rails console で
Page.joins(:records)
    .group('records.what')
    .having('count(*) >= 5')
    .count
    .sort_by { |_, count| -count }

# => {"シャワー"=>45, "昼食"=>52, "夕食"=>48, ...}


frequent_whats = Record.group(:what).having('count(*) >= 5').count.keys

frequent_whats.map do |what|
  records = Record.where(what: what)
  durations = records.map(&:duration_minutes).compact
  
  next if durations.empty?
  
  count = durations.size
  avg = durations.sum.to_f / count
  median = durations.sort[durations.size / 2]
  
  # 分散と標準偏差
  variance = durations.map { |d| (d - avg) ** 2 }.sum / count
  std_dev = Math.sqrt(variance)
  
  {
    what: what,
    count: count,
    avg: "#{(avg / 60).to_i}h#{(avg % 60).to_i}m",
    median: "#{(median / 60).to_i}h#{(median % 60).to_i}m",
    std_dev: "#{(std_dev / 60).to_i}h#{(std_dev % 60).to_i}m",
    min: "#{(durations.min / 60).to_i}h#{(durations.min % 60).to_i}m",
    max: "#{(durations.max / 60).to_i}h#{(durations.max % 60).to_i}m"
  }
end.compact.each do |stats|
  puts "#{stats[:what]}: #{stats[:count]}回"
  puts "  平均: #{stats[:avg]} | 中央値: #{stats[:median]} | 標準偏差: #{stats[:std_dev]}"
  puts "  範囲: #{stats[:min]} - #{stats[:max]}"
  puts
end

# semester projectとか

Project
- name: "semester projectレポート"
- deadline: date
- estimated_hours: 40
- status: in_progress

ProjectActivity (実績の紐付け)
- project_id
- record_id
- detected_at: datetime (自動紐付けされた時刻)

# migration
rails g model Project name:string deadline:date estimated_hours:integer
rails g model ProjectActivity project:references record:references

# 手動で紐付け（まずは）
project = Project.create(name: 'semester project', deadline: '2025-01-18', estimated_hours: 40)

# rails console で過去のレコードを検索
records = Record.where("what LIKE ?", "%semester%")
records.each { |r| ProjectActivity.create(project: project, record: r) }

# 進捗確認
project.records.sum(:duration_minutes) / 60.0  # => 12.5時間