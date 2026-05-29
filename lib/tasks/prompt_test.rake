namespace :prompt do
  desc "Test prompt parsing accuracy"
  task test: :environment do
    test_cases = [
      # テスト1: 「まで」の連続（プロンプトにない時刻バリエーション）
      {
        content: "19:52までパスタ作ってくれてる間ぼーっとする。\nTranscend tales浦島回読む。化物になったのはなんで？ラヴクラフト読むカー\n22:00まであれこれ雑談する。\n23:42までベルリン調べる。\n23:52まで日記書く。",
        date: Date.parse("2025-11-18"),
        expected: [
          { end: "2025-11-18 19:52", what: "ぼーっと", category: "娯楽/だらだら" },
          { start: "2025-11-18 19:52", end: "2025-11-18 22:00", what: "雑談", category: "娯楽/だらだら" },
          { start: "2025-11-18 22:00", end: "2025-11-18 23:42", what: "ベルリン調べる", category: "趣味" },
          { start: "2025-11-18 23:42", end: "2025-11-18 23:52", what: "日記書く", category: "趣味" }
        ]
      },
      # テスト2: 時刻明示（「まで」なし）とメモの混在
      {
        content: "18:58までembedding関連のchatgptのログ見直して何やってたか思い出す。こんな話だったかなあw\n19:04までくねくねする。帰るか〜〜19:32帰宅。\n20:10までネットサーフィン。\n20:35までembedding関連でllmと壁打ち。いろいろやりようがあって迷っちゃうわね。迷わずスケッチ。\n20:42までネットサーフィン。",
        date: Date.parse("2026-01-10"),
        expected: [
          { end: "2026-01-10 18:58", what: "chatgpt", category: "研究" },
          { start: "2026-01-10 18:58", end: "2026-01-10 19:04", what: "くねくね", category: "娯楽/だらだら" },
          { start: "2026-01-10 19:04", end: "2026-01-10 19:32", what: "移動", category: "移動" },
          { start: "2026-01-10 19:32", end: "2026-01-10 20:10", what: "ネットサーフィン", category: "娯楽/だらだら" },
          { start: "2026-01-10 20:10", end: "2026-01-10 20:35", what: "embedding", category: "研究" },
          { start: "2026-01-10 20:35", end: "2026-01-10 20:42", what: "ネットサーフィン", category: "娯楽/だらだら" }
        ]
      },
      # テスト3: メモ・予定が大量に混在
      {
        content: <<~CONTENT,
          19:06までXXX検証。シングルノードの場合、UUUと同じ結果が出るようにした。
          scrapbox（プロジェクト管理、メモ）にもtokimetri（時間管理）にも似たような内容書くのだるいなあ、と思いつついい方法が思いつかない。
          19:14までscrapboxに追記。腹減った。

          (1915 2500にはねたい。あと5.5h)
          シャワー0.5h
          夕食1h
          ---2.5h 残り---
          研究

          19:52帰宅。メトロの表示バグってて（バグりすぎ）反対方向差してて戸惑ってる人がいたので話しかける。新セメスターなので新しい学生が増えてきている。てかles cours de français intensifsはもうやってるのか。
          20:16までシャワー。
        CONTENT
        date: Date.parse("2026-01-15"),
        expected: [
          { end: "2026-01-15 19:06", what: "検証", category: "研究" },
          { start: "2026-01-15 19:06", end: "2026-01-15 19:14", what: "scrapbox", category: "事務" },
          { start: "2026-01-15 19:14", end: "2026-01-15 19:52", what: "移動", category: "移動" },
          { start: "2026-01-15 19:52", end: "2026-01-15 20:16", what: "シャワー", category: "生活" }
        ]
      },
      # テスト4: 「から」と明示時刻の混在（エッジケース）
      {
        content: "21:15からNetflix観る。23:45映画終わる。0:20までシャワー。1:05就寝。",
        date: Date.parse("2026-02-01"),
        expected: [
          { start: "2026-02-01 21:15", end: "2026-02-01 23:45", what: "Netflix", category: "娯楽/だらだら" },
          { start: "2026-02-01 23:45", end: "2026-02-02 00:20", what: "シャワー", category: "生活" },
          { start: "2026-02-02 00:20", end: "2026-02-02 01:05", what: nil, category: nil },
          { start: "2026-02-02 01:05", end: nil, what: "就寝", category: "睡眠" }
        ]
      },
      # テスト5: 起床パターンのバリエーション（「目を覚ます」以外）
      {
        content: "07:45起床。08:15までぼーっとする。08:40まで朝食。09:10までメール返信。",
        date: Date.parse("2026-02-05"),
        expected: [
          { start: "2026-02-05 07:45", end: "2026-02-05 08:15", what: "ぼーっと", category: "娯楽/だらだら" },
          { start: "2026-02-05 08:15", end: "2026-02-05 08:40", what: "朝食", category: "生活" },
          { start: "2026-02-05 08:40", end: "2026-02-05 09:10", what: "メール返信", category: "事務" }
        ]
      },
      # テスト6: 微妙な表現のバリエーション（「まで」の位置が違う）
      {
        content: "研究を18:30まで。19:00まで夕食食べる。20:15まで論文読む。",
        date: Date.parse("2026-02-10"),
        expected: [
          { end: "2026-02-10 18:30", what: "研究", category: "研究" },
          { start: "2026-02-10 18:30", end: "2026-02-10 19:00", what: "夕食", category: "生活" },
          { start: "2026-02-10 19:00", end: "2026-02-10 20:15", what: "論文", category: "研究" }
        ]
      }
    ]

    passed = 0
    failed = 0

    test_cases.each_with_index do |test_case, i|
      puts "\n" + "=" * 80
      puts "Test Case #{i + 1}"
      puts "=" * 80
      puts "Content:\n#{test_case[:content]}"
      puts "-" * 80

      page = Page.create!(content: test_case[:content], date: test_case[:date])

      begin
        page.analyze_and_update

        if validate_records(page.records.order(:start_time), test_case[:expected])
          puts "✓ PASS"
          passed += 1
        else
          puts "✗ FAIL"
          failed += 1
        end
      rescue => e
        puts "✗ ERROR: #{e.message}"
        puts e.backtrace.first(5).join("\n")
        failed += 1
      ensure
        page.destroy
      end
    end

    puts "\n" + "=" * 80
    puts "Summary"
    puts "=" * 80
    puts "Passed: #{passed} / #{test_cases.size}"
    puts "Failed: #{failed} / #{test_cases.size}"
    puts "Success rate: #{(passed.to_f / test_cases.size * 100).round(2)}%"

    exit(1) if failed > 0
  end

  def validate_records(actual_records, expected)
    if actual_records.size != expected.size
      puts "  Expected #{expected.size} records, got #{actual_records.size}"
      pp actual_records.map { |r| { start: r.start_time&.strftime("%Y-%m-%d %H:%M"), end: r.end_time&.strftime("%Y-%m-%d %H:%M"), what: r.what, category: r.category } }
      return false
    end

    all_valid = true
    logs = ""

    expected.each_with_index do |exp, i|
      record = actual_records[i]

      logs += "\n  Record #{i + 1}:"

      # start のチェック（期待値が指定されている場合のみ）
      if exp[:start]
        expected_start = exp[:start]
        actual_start = record.start_time&.strftime("%Y-%m-%d %H:%M")

        if actual_start != expected_start
          logs += "    ✗ start: expected '#{expected_start}', got '#{actual_start}'"
          all_valid = false
        end
      end

      # end のチェック（期待値が指定されている場合のみ）
      if exp.key?(:end)
        expected_end = exp[:end]
        actual_end = record.end_time&.strftime("%Y-%m-%d %H:%M")

        if actual_end != expected_end
          logs += "    ✗ end: expected '#{expected_end}', got '#{actual_end}'"
          all_valid = false
        end
      end

      # what のチェック（期待値が指定されている場合のみ）
      if exp.key?(:what)
        expected_what = exp[:what]
        actual_what = record.what

        if expected_what.nil?
          if actual_what != expected_what
            logs += "    ✗ what: expected '#{expected_what}', got '#{actual_what}'"
            all_valid = false
          end
        elsif actual_what.nil? || !actual_what.include?(expected_what)
          logs += "    ✗ what: expected to include '#{expected_what}', got '#{actual_what}'"
          all_valid = false
        end
      end

      # category のチェック（期待値が指定されている場合のみ）
      if exp.key?(:category)
        expected_category = exp[:category]
        actual_category = record.category

        if actual_category != expected_category
          logs += "    ✗ category: expected '#{expected_category}', got '#{actual_category}'"
          all_valid = false
        end
      end
    end

    print logs unless all_valid

    all_valid
  end
end
