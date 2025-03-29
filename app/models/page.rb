class Page < ApplicationRecord
  # has_rich_text :content
  validates :date, presence: true
  validates :content, presence: true

  def analyze_and_update
    client = OpenAI::Client.new(access_token: Rails.application.credentials.openai.api_key)
    response = client.responses.create(
      parameters: {
        model: 'gpt-4o',
        input: prompt,
      }
    )

    pp response

    self.update(analyzed_content: response.dig('output', 0, 'content', 0, 'text'))
  end

  private
    def prompt
      today = self.date.strftime('%Y/%m/%d')

      <<-PROMPT
      #{self.content}      
      
      上記の内容を
      
      start,end,what,category
      2025-03-20 14:30,2025-03-20 15:45,航空券とかESTAとか申請する,事務
      ...
      2025-03-20 22:34,2025-03-20 23:00,moyaru書く,趣味
      2025-03-20 23:00,2025-03-21 5:00,睡眠,生活
      ...
      
      のように何をしていたかわかるようにCSVでまとめてください。start,endカラムはyyyy-MM-dd HH:mmの形式とします。わからない部分は_で埋めてください。何をしていたか読み取れない時間帯も,_で埋めてください。また、
      
      - categoryについては、what列の情報をもとに、「睡眠」「事務作業」「研究」「趣味」「だらだら」「娯楽」「生活」「仕事」のうち、一番近いもので埋めてください。
      - 「Tier4」は仕事のことです。
      - 「日記アプリの開発」は趣味カテゴリです。
      - 睡眠は睡眠カテゴリです。睡眠以外のタスクは睡眠カテゴリに分類しないでください。
      
      「0830起床。朝食。40分絵を描く。 1014ぐずる」のように、途中のタスクの長さだけが明記されている場合は、「08:30,09:34,起床  09:34,10:14,絵を描く」のように、順番に応じて時刻を設定してください。
      日付がわからない場合は, #{today}としてください。

      応答には上記CSV以外の情報は含まないようにしてください。コードをくくる ``` も含めないようにしてください。
      PROMPT
    end
end
