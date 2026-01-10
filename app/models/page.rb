class Page < ApplicationRecord
  # has_rich_text :content
  validates :date, presence: true
  validates :content, presence: true

  has_many :records, dependent: :destroy

  def wake_time
    if last = records.where(category: '睡眠').order(:end_time).last
      return last.end_time
    end

    if yesterday_page = Page.find_by(date: date - 1.day)
      if yesterday_last = yesterday_page.records.where(category: '睡眠').order(:end_time).last
        return yesterday_last.end_time
      end
    end

    records.first&.start_time
  end

  def self.average_wake_time(pages)
    wake_times = pages.map(&:wake_time).compact
    return nil if wake_times.empty?
  
    total_minutes = wake_times.sum { |t| t.hour * 60 + t.min }
    avg_minutes = total_minutes / wake_times.size
  
    Time.parse("#{avg_minutes / 60}:#{avg_minutes % 60}")
  end

  def analyze_and_update
    # show rails env
    client = OpenAI::Client.new(access_token: Rails.application.credentials.openai.api_key)
    response = client.responses.create(
      parameters: {
        model: 'gpt-5',
        input: prompt,
      }
    )

    pp response

    self.update(analyzed_content: response.dig('output', 0, 'content', 0, 'text'))

    # add records
    self.records.destroy_all
    
    csv_data = CSV.parse(self.analyzed_content, headers: true)
    csv_data.each do |row|
      self.records.create(
        start_time: row['start'],
        end_time: row['end'],
        what: row['what'],
        category: row['category']
      )
    end

    merge_sleep_records
  end

  def merge_sleep_records
    # 前日の最後の睡眠レコード（就寝）を探す
    yesterday_page = Page.find_by(date: date - 1.day)
    return true unless yesterday_page

    yesterday_sleep = yesterday_page.records.order(:start_time).last
    return true unless yesterday_sleep && yesterday_sleep.category == '睡眠'
  
    if yesterday_sleep.end_time.nil? 
      today_earliest = records.order(:start_time).first
      yesterday_sleep.update(end_time: today_earliest.start_time)    
    else
      true
    end
  end

  def category_durations_minutes
    summary = Hash.new(0)
    
    records.each do |record|
      if dur = record.duration_minutes 
        summary[record.category] += dur
      end
    end
    
    summary.sort_by { |_, duration| -duration }
  end

  def self.calculate_category_total(pages)
    return {} if pages.empty?
    
    total_by_category = Hash.new(0)
    
    pages.each do |page|
      page.category_durations_minutes.each do |category, duration|
        total_by_category[category] += duration
      end
    end
    
    # 時間が多い順にソート
    total_by_category.sort_by { |_, total| -total }.to_h
  end

  def self.calculate_category_averages(pages)
    self.calculate_category_total(pages).transform_values do |total_minutes|
      (total_minutes.to_f / pages.size).round(2)
    end
  end

  private
    def prompt
      today = self.date.strftime('%Y/%m/%d')
      cat = Setting.instance.categories.map { |k, v| "「#{k}」" }.join

      <<-PROMPT
      #{self.content}      
      
      上記の内容を
      
      start,end,what,category
      2025-03-20 14:30,2025-03-20 15:45,航空券とかESTAとか申請する,事務
      ...
      2025-03-20 22:34,2025-03-20 23:00,moyaru書く,趣味
      2025-03-20 23:00,2025-03-21 5:00,睡眠,生活
      ...
      
      のように何をしていたかわかるようにCSVでまとめてください。start,endカラムはyyyy-MM-dd HH:mmの形式とします。わからない部分は_で埋めてください。何をしていたか読み取れない時間帯も,_で埋めてください。categoryについては、what列の情報をもとに、#{cat}のうち、一番近いもので埋めてください。

      また、
      - 「Tier4」は仕事のことです。
      - 「日記アプリの開発」は趣味カテゴリです。
      - 研究室での「雑談」はだらだらカテゴリです。
      - 睡眠は睡眠カテゴリです。睡眠以外のタスクは睡眠カテゴリに分類しないでください。
      - 仕事や就活は判断が難しいです。2時間ぐらい続いているとただのネットサーフィンになりがちなので、だらだらカテゴリに移動してください。エントリーシートやSPIは事務カテゴリに分類してください。
      
      「0830起床。朝食。40分絵を描く。 1014ぐずる」のように、途中のタスクの長さだけが明記されている場合は、「08:30,09:34,起床  09:34,10:14,絵を描く」のように、順番に応じて時刻を設定してください。
      日付がわからない場合は, #{today}としてください。基本的には出来事は時系列順で記述されています。最後のほうの出来事は日付が変わった後で、#{today}の次の日の早朝の出来事かもしれません。

      「〇〇。半分ぐらいネット見てた」などの場合は、「〇〇」と「ネット見てた（だらだら）」の間の時間を均等に分割して記録してください。

      たとえば、「20:23から上野でタブナイ観る。22:30映画館出る。0:05帰宅。0:30までシャワー浴びた。0:55就寝。」という記述は
        2025-03-20 20:23,2025-03-21 22:30,タブナイ観る,娯楽
        2025-03-20 22:30,2025-03-21 0:05,移動,移動
        2025-03-21 0:05,2025-03-21 0:30,シャワー浴びた,生活
        2025-03-21 0:30,2025-03-21 0:55,_,_
        2025-03-21 0:55,_,就寝,睡眠
      のように出力してください。

      たとえば、
      「23:27までtokimetri開発. 週次レビュー用の機能作る。Claude、速い。
      0:30までtokimetri開発。楽しいが若干ダレてくる。
      01:10までネットサーフィン。scp読む。」
      という記述は、
        2025-11-20 23:27,2025-11-21 0:30,tokimetri開発,趣味
        2025-11-21 0:30,2025-11-21 1:10,ネットサーフィン,趣味
      のように出力してください。

      応答には上記CSV（ヘッダと中身）以外の情報は含まないようにしてください。コードをくくる ``` も含めないようにしてください。
      PROMPT
    end
end
