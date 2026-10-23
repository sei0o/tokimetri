require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in
    @date = Date.new(2026, 9, 9)
    travel_to Time.zone.local(2026, 9, 9, 12, 0)
  end

  test "log ページが開く" do
    get log_path(@date.strftime("%Y%m%d"))
    assert_response :success
  end

  test "経過時間が出る" do
    page = Page.create!(date: @date)
    page.records.create!(start_time: "2026-09-09 09:00", end_time: "2026-09-09 10:30", what: "研究", category: "研究")

    get log_path(@date.strftime("%Y%m%d"))
    assert_select "td.duration", text: "1:30"
  end

  test "時刻は「1012」でも「10:12」として記録される" do
    patch update_date_page_path(@date.strftime("%Y%m%d")), params: {
      from: "log",
      page: { date: @date, records_attributes: { "0" => { kind: "activity", start_time: "930", end_time: "1012", what: "研究" } } }
    }

    record = Page.find_by(date: @date).records.first
    assert_equal [ "09:30", "10:12" ], [ record.start_time, record.end_time ].map { _1.strftime("%H:%M") }
  end

  test "レコードとメモを作れる" do
    patch update_date_page_path(@date.strftime("%Y%m%d")), params: {
      from: "log",
      page: {
        date: @date,
        records_attributes: {
          "0" => { kind: "activity", start_time: "9:00", end_time: "10:30", what: "研究", category: "研究" },
          "1" => { kind: "note", start_time: "10:40", what: "今日は集中できた" },
          "2" => { kind: "activity", start_time: "", end_time: "25:00", what: "開発", category: "趣味" },
          "3" => { kind: "activity", start_time: "", end_time: "", what: "", category: "" }
        }
      }
    }
    assert_redirected_to log_path(@date.strftime("%Y%m%d"))

    page = Page.find_by(date: @date)
    assert_equal 3, page.records.count
    assert_equal 2, page.records.activities.count

    note = page.records.find_by(kind: "note")
    assert_equal "今日は集中できた", note.what
    assert_nil note.duration_minutes

    dev = page.records.find_by(what: "開発")
    assert_equal Time.zone.local(2026, 9, 9, 10, 30), dev.start_time
    assert_equal Time.zone.local(2026, 9, 10, 1, 0), dev.end_time
  end

  test "メモは開始時刻の引き継ぎを進めない" do
    patch update_date_page_path(@date.strftime("%Y%m%d")), params: {
      from: "log",
      page: {
        date: @date,
        records_attributes: {
          "0" => { kind: "activity", start_time: "9:00", end_time: "10:00", what: "研究", category: "研究" },
          "1" => { kind: "note", start_time: "", what: "メモ" },
          "2" => { kind: "activity", start_time: "", end_time: "11:00", what: "散歩", category: "移動" }
        }
      }
    }

    page = Page.find_by(date: @date)
    assert_equal Time.zone.local(2026, 9, 9, 10, 0), page.records.find_by(what: "メモ").start_time
    assert_equal Time.zone.local(2026, 9, 9, 10, 0), page.records.find_by(what: "散歩").start_time
  end

  test "メモは集計と睡眠の推定から外れる" do
    page = Page.create!(date: @date)
    page.records.create!(kind: "activity", start_time: "2026-09-09 09:00", end_time: "2026-09-09 10:00", what: "研究", category: "研究")
    page.records.create!(kind: "note", start_time: "2026-09-09 10:30", what: "メモ")

    assert_equal [ [ "研究", 60 ] ], page.category_durations_minutes

    page.add_sleep_if_missing
    sleep_record = page.records.activities.last
    assert_equal "睡眠", sleep_record.category
    assert_equal Time.zone.local(2026, 9, 9, 10, 0), sleep_record.start_time
  end

  test "自動保存は作った行の id を行番号ごとに返す" do
    patch update_date_page_path(@date.strftime("%Y%m%d")), as: :json, params: {
      from: "log",
      page: {
        date: @date,
        records_attributes: {
          "100" => { kind: "activity", start_time: "9:00", end_time: "10:00", what: "研究", category: "研究" },
          "101" => { kind: "activity", start_time: "", end_time: "", what: "", category: "" },
          "102" => { kind: "note", start_time: "10:30", what: "メモ" }
        }
      }
    }
    assert_response :success

    page = Page.find_by(date: @date)
    ids = response.parsed_body["ids"]
    assert_equal %w[100 102], ids.keys
    assert_equal ids["100"], page.records.find_by(what: "研究").id
    assert_equal ids["102"], page.records.find_by(what: "メモ").id
  end

  test "自動保存は id を送れば行を増やさず、削除した行は消える" do
    page = Page.create!(date: @date)
    record = page.records.create!(start_time: "2026-09-09 09:00", end_time: "2026-09-09 10:00", what: "研究", category: "研究")
    other = page.records.create!(start_time: "2026-09-09 10:00", end_time: "2026-09-09 11:00", what: "散歩", category: "移動")

    patch update_date_page_path(@date.strftime("%Y%m%d")), as: :json, params: {
      from: "log",
      page: {
        date: @date,
        records_attributes: {
          "0" => { id: record.id, kind: "activity", start_time: "9:00", end_time: "10:30", what: "研究", category: "研究" },
          "1" => { id: other.id, kind: "activity", start_time: "10:00", end_time: "11:00", what: "散歩", category: "移動", _destroy: "1" }
        }
      }
    }
    assert_response :success
    assert_equal({}, response.parsed_body["ids"])
    assert_equal [ "研究" ], page.records.reload.map(&:what)
    assert_equal Time.zone.local(2026, 9, 9, 10, 30), record.reload.end_time
  end

  test "過去の記録からカテゴリを推測する" do
    page = Page.create!(date: @date - 1.day)
    3.times { page.records.create!(what: "ネットサーフィン", category: "娯楽/だらだら") }
    page.records.create!(kind: "note", what: "床屋", category: "生活")

    assert_equal "娯楽/だらだら", Record.guess_category("ネットサーフィン")
    assert_equal "娯楽/だらだら", Record.guess_category("ネットサーフィンする")
    assert_nil Record.guess_category("床屋"), "メモは学習元にしない"
    assert_nil Record.guess_category("まったく違うこと")
    assert_nil Record.guess_category("")
  end

  test "カテゴリの推測を返す" do
    page = Page.create!(date: @date - 1.day)
    page.records.create!(what: "研究", category: "研究")

    get category_path(what: "研究")
    assert_equal "研究", response.body

    get category_path(what: "まったく違うこと")
    assert_equal "", response.body
  end

  test "analyze はメモを消さない" do
    page = Page.create!(date: @date, content: "9:00まで研究")
    page.records.create!(kind: "note", start_time: "2026-09-09 10:30", what: "残るメモ")
    page.records.create!(kind: "activity", start_time: "2026-09-09 09:00", end_time: "2026-09-09 10:00", what: "消える", category: "研究")

    page.apply_parsed_records([ { "start" => "2026-09-09 11:00", "end" => "2026-09-09 12:00", "what" => "新しい", "category" => "研究" } ])

    assert_equal [ "残るメモ", "新しい", "就寝" ], page.records.reload.map(&:what)
  end
  test "保存すると前日に睡眠を補い、書いている日には足さない" do
    yesterday = Page.create!(date: @date - 1.day)
    yesterday.records.create!(kind: "activity", start_time: "2026-09-08 22:00", end_time: "2026-09-08 23:30", what: "読書", category: "趣味")

    patch update_date_page_path(@date.strftime("%Y%m%d")), as: :json, params: {
      page: {
        date: @date,
        records_attributes: {
          "100" => { kind: "activity", start_time: "8:00", end_time: "9:00", what: "朝食", category: "食事" }
        }
      }
    }
    assert_response :success

    sleep_record = yesterday.records.activities.last
    assert_equal "睡眠", sleep_record.category
    assert_equal Time.zone.local(2026, 9, 8, 23, 30), sleep_record.start_time
    assert_equal Time.zone.local(2026, 9, 9, 8, 0), sleep_record.end_time
    assert_equal [ "朝食" ], Page.find_by(date: @date).records.map(&:what)
  end
end
