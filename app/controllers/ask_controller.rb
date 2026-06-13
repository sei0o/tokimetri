class AskController < ApplicationController
  def index
  end

  def create
    @question = params[:question].to_s.strip
    return redirect_to ask_path unless @question.present?

    @reply, @sqls = ask(@question)
    render :index
  end

  private

  def system_prompt
    samples = ActiveRecord::Base.connection.execute(
      "SELECT what FROM records WHERE end_time IS NOT NULL ORDER BY RANDOM() LIMIT 30"
    ).to_a.map { |r| r["what"] }.compact.uniq.first(25).join(", ")

    <<~PROMPT
      あなたはユーザーの日記アプリのアシスタントです。SQLiteのrecordsテーブル（#{Record.count}件）にユーザー自身の活動記録が入っています。

      テーブル構造:
      - records: id, page_id, what(TEXT 活動名), category(TEXT), start_time(DATETIME), end_time(DATETIME)
      - pages: id, date(DATE), content(TEXT)
      - JOIN: records.page_id = pages.id
      - 所要時間(分) = (julianday(end_time) - julianday(start_time)) * 24 * 60

      whatフィールドの実例: #{samples}

      必ずrun_sqlツールで実データを検索してから回答すること。自分の知識で答えないこと。
      回答はシンプルなHTMLで（<p><ul><table>等のみ、html/head/bodyタグ不要）、日本語で。
    PROMPT
  end

  RUN_SQL_TOOL = {
    type: "function",
    function: {
      name: "run_sql",
      description: "SQLiteデータベースにSELECTクエリを実行する",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string", description: "実行するSELECT文" }
        },
        required: ["query"]
      }
    }
  }.freeze

  def ask(question)
    client = OpenAI::Client.new(api_key: Rails.application.credentials.openai.api_key)
    messages = [{ role: "user", content: question }]
    sys = system_prompt
    sqls = []

    10.times do
      response = client.chat.completions.create(
        model: "gpt-5.2",
        messages: [{ role: "system", content: sys }] + messages,
        tools: [RUN_SQL_TOOL]
      )

      choice = response.choices.first
      tool_calls = choice.message.tool_calls.to_a
      Rails.logger.info "[Ask] finish_reason=#{choice.finish_reason} tool_calls=#{tool_calls.length}"

      if choice.finish_reason.to_s == "tool_calls" && tool_calls.any?
        messages << {
          role: "assistant",
          content: nil,
          tool_calls: tool_calls.map { |tc|
            { id: tc.id, type: "function", function: { name: tc.function.name, arguments: tc.function.arguments } }
          }
        }

        tool_calls.each do |tc|
          sql = JSON.parse(tc.function.arguments)["query"]
          Rails.logger.info "[Ask] SQL: #{sql}"
          result = run_sql(sql)
          Rails.logger.info "[Ask] rows: #{result.is_a?(Array) ? result.length : 'error'}"
          sqls << sql
          messages << { role: "tool", tool_call_id: tc.id, content: result.first(100).to_json }
        end
      else
        return choice.message.content.presence || "<p>回答を取得できませんでした。</p>", sqls
      end
    end

    [ "<p>ループ回数が上限に達しました。</p>", sqls ]
  rescue => e
    Rails.logger.error "[Ask] error: #{e.class}: #{e.message}"
    [ "<p>エラーが発生しました: #{e.message}</p>", sqls ]
  end

  def run_sql(sql)
    raise "SELECT以外は実行できません" unless sql.strip.upcase.start_with?("SELECT")

    db = SQLite3::Database.new(Rails.configuration.database_configuration[Rails.env]["database"])
    db.results_as_hash = true
    db.execute(sql)
  rescue => e
    { error: e.message }
  ensure
    db&.close
  end
end
