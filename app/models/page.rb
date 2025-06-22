class Page < ApplicationRecord
  # has_rich_text :content
  validates :date, presence: true
  validates :content, presence: true

  ## maps between category name and color
  CATEGORIES = {
    '睡眠' => '#3c4c5d',
    '事務' => '#2d8a44',
    '研究' => '#4175c9',
    '趣味' => '#c43dad',
    'だらだら' => '#eb0348',
    '娯楽' => '#b16128',
    '生活' => '#46843e',
    '仕事' => '#357e9e',
  }
  

  def analyze_and_update
    # show rails env
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
      cat = CATEGORIES.map { |k, v| "「#{k}」" }.join

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
      - 睡眠は睡眠カテゴリです。睡眠以外のタスクは睡眠カテゴリに分類しないでください。
      
      「0830起床。朝食。40分絵を描く。 1014ぐずる」のように、途中のタスクの長さだけが明記されている場合は、「08:30,09:34,起床  09:34,10:14,絵を描く」のように、順番に応じて時刻を設定してください。
      日付がわからない場合は, #{today}としてください。基本的には出来事は時系列順で記述されています。最後のほうの出来事は日付が変わった後で、#{today}の次の日の早朝の出来事かもしれません。

      たとえば、「20:23から上野でタブナイ観る。0:05帰宅。シャワー浴びた。0:25就寝。」という記述は
        2025-03-20 20:23,2025-03-21 0:05,タブナイ観る,娯楽
        2025-03-21 0:05,2025-03-21 0:25,シャワー浴びた,生活
        2025-03-21 0:25,_,就寝,睡眠
      のように出力してください。

      応答には上記CSV以外の情報は含まないようにしてください。コードをくくる ``` も含めないようにしてください。
      PROMPT
    end
end
