class ActivityRecord < OpenAI::BaseModel
  required :start, String, nil?: true
  required :end, String, nil?: true
  required :what, String, nil?: true
  required :category, String, nil?: true
end

class ActivityRecords < OpenAI::BaseModel
  required :records, OpenAI::ArrayOf[ActivityRecord]
end

class Page < ApplicationRecord
  # has_rich_text :content
  validates :date, presence: true
  validates :content, presence: true

  has_many :records, dependent: :destroy

  def wake_time
    if last = records.where(category: "睡眠").order(:end_time).last
      return last.end_time
    end

    if yesterday_page = Page.find_by(date: date - 1.day)
      if yesterday_last = yesterday_page.records.where(category: "睡眠").order(:end_time).last
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
    client = OpenAI::Client.new(api_key: Rails.application.credentials.openai.api_key)

    chat_completion = client.chat.completions.create(
      model: "gpt-5.2",
      temperature: 0,
      messages: [
        { role: :user, content: prompt }
      ],
      response_format: ActivityRecords
    )

    parsed = chat_completion.choices.first.message.parsed

    # JSON として保存
    self.update(analyzed_content: { records: parsed.records }.to_json)

    # add records
    self.records.destroy_all

    parsed.records.each do |record|
      self.records.create(
        start_time: record.start,
        end_time: record.end,
        what: record.what,
        category: record.category
      )
    end

    merge_sleep_records
  end

  def merge_sleep_records
    # 前日の最後の睡眠レコード（就寝）を探す
    yesterday_page = Page.find_by(date: date - 1.day)
    return true unless yesterday_page

    yesterday_sleep = yesterday_page.records.order(:start_time).last
    return true unless yesterday_sleep && yesterday_sleep.category == "睡眠"

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
      today = self.date.strftime("%Y-%m-%d")
      cat = Setting.instance.categories.map { |k, v| "「#{k}」" }.join

      <<-PROMPT
      ## ★最重要: 時刻の読み方（絶対に守ること）

      - 「XX:XXまで〜」→ そのタスクの **end（終了時刻）** = XX:XX
      - 「XX:XXから〜」→ そのタスクの **start（開始時刻）** = XX:XX
      - 連続するタスクは「前のタスクの end = 次のタスクの start」

      ## 出力形式

      以下の記録を JSON に変換してください。

      {"start": "yyyy-MM-dd HH:mm", "end": "yyyy-MM-dd HH:mm", "what": "タスク名", "category": "カテゴリ"}

      - 時刻不明 → null
      - 日付不明 → #{today}（末尾は翌日早朝の場合あり）

      ## カテゴリ

      #{cat}から最も近いものを選ぶ。

      - 「Tier4」= 仕事
      - 趣味: 読書・絵を描く・tokimetri開発・お菓子作り・ゲーム（ソシャゲ以外）・ブログ執筆・日記書く・ジャーナリングなど
      - 娯楽/だらだら: ぼーっとする・ネットサーフィン・YouTube・ソシャゲ・研究室での雑談など
      - 研究: 実験・検証・論文読む・発表・輪講・研究コーディングなど（Tier4の仕事ではない技術的作業）
      - 生活: 週次レビューなど / 講義: 定期試験など / 事務: 留学報告書・エントリーシート・SPIなど
      - 睡眠カテゴリは睡眠のみ（例外なし）
      - 仕事・就活が 2 時間超続く場合 → 娯楽/だらだら

      ## 変換ルール

      - 「起床」「目を覚ます」は瞬間的な出来事 → 次のタスクの start として扱う
      - 「〇〇。半分ぐらい△△してた」→ 時間を均等分割して 2 レコードにする
      - 途中のタスクの長さだけ明記の場合（例:「40分〇〇」）→ 順番から時刻を計算
      - 予定・メモ・感想が混在している場合は無視する
      - **タイムスタンプ（HH:MM）を含まない文は、単独のアクティビティレコードにしないでください。** 感想・疑問・読書メモなどは無視するか、前後のタスクの説明として扱ってください。
      - **「HH:MM帰宅」「HH:MM着」などの到着表現は、直前のタスク終了時刻からその時刻までを「移動」カテゴリのレコードとして扱ってください。** 途中にメモや計画ブロックが挟まれていても同様です。

      ## 変換例

      入力: 「23:27までシャワー。0:30までtokimetri開発。01:10までネットサーフィン。」
      出力:
      {"start": "（適切に設定）", "end": "2025-11-20 23:27", "what": "シャワー", "category": "生活"}
      {"start": "2025-11-20 23:27", "end": "2025-11-21 00:30", "what": "tokimetri開発", "category": "趣味"}
      {"start": "2025-11-21 00:30", "end": "2025-11-21 01:10", "what": "ネットサーフィン", "category": "娯楽/だらだら"}

      入力: 「19:52までぼーっとする。\nTranscend tales読む。おもしろい。\n22:00まであれこれ雑談する。」
      出力:
      {"start": null, "end": "2025-11-18 19:52", "what": "ぼーっとする", "category": "娯楽/だらだら"}
      {"start": "2025-11-18 19:52", "end": "2025-11-18 22:00", "what": "雑談", "category": "娯楽/だらだら"}
      ※ タイムスタンプのない「Transcend tales読む」は単独レコードにせず、前後のタスクに吸収させる

      入力: 「19:14までscrapbox追記。\n\n（今日の計画：シャワー0.5h...）\n\n19:52帰宅。20:16までシャワー。」
      出力:
      {"start": "（適切に設定）", "end": "2026-01-15 19:14", "what": "scrapbox追記", "category": "事務"}
      {"start": "2026-01-15 19:14", "end": "2026-01-15 19:52", "what": "移動", "category": "移動"}
      {"start": "2026-01-15 19:52", "end": "2026-01-15 20:16", "what": "シャワー", "category": "生活"}
      ※ 計画ブロックは無視し、「19:52帰宅」は19:14からの移動の終着点として扱う

      入力: 「20:23から上野でタブナイ観る。22:30映画館出る。0:05帰宅。0:30までシャワー。0:40までSNS見る。0:55就寝。」
      出力:
      {"start": "2025-03-20 20:23", "end": "2025-03-20 22:30", "what": "タブナイ観る", "category": "娯楽/だらだら"}
      {"start": "2025-03-20 22:30", "end": "2025-03-21 00:05", "what": "移動", "category": "移動"}
      {"start": "2025-03-21 00:05", "end": "2025-03-21 00:30", "what": "シャワー", "category": "生活"}
      {"start": "2025-03-21 00:30", "end": "2025-03-21 00:40", "what": "SNS見る", "category": "娯楽/だらだら"}
      {"start": "2025-03-21 00:40", "end": "2025-03-21 00:55", "what": null, "category": null}
      {"start": "2025-03-21 00:55", "end": null, "what": "就寝", "category": "睡眠"}

      入力: 「08:30目を覚ます。09:00まで布団でうじうじする。09:25までメッセージ3つ返す。」
      出力:
      {"start": "2025-12-01 08:30", "end": "2025-12-01 09:00", "what": "布団でうじうじ", "category": "娯楽/だらだら"}
      {"start": "2025-12-01 09:00", "end": "2025-12-01 09:25", "what": "メッセージ3つ返す", "category": "事務"}

      入力: 「16:06まで留学書類書く。16:46まで研究する。うち20分ぐらいネットサーフィン。」
      出力:
      {"start": "（適当）", "end": "2025-12-15 16:06", "what": "留学書類書く", "category": "事務"}
      {"start": "2025-12-15 16:06", "end": "2025-12-15 16:26", "what": "研究する", "category": "研究"}
      {"start": "2025-12-15 16:26", "end": "2025-12-15 16:46", "what": "ネットサーフィン", "category": "娯楽/だらだら"}

      ## ★再確認: 時刻の読み方

      - 「XX:XXまで〜」→ end = XX:XX（終了時刻）
      - 「XX:XXから〜」→ start = XX:XX（開始時刻）

      ## 変換対象

      #{self.content}
      PROMPT
    end
end
