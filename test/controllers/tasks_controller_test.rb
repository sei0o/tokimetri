require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in
  end

  test "inbox で追加・書き換え・移動をまとめてできる" do
    keep = Task.create!(content: "セブン銀行")
    move = Task.create!(content: "戸籍")

    patch tasks_path, params: {
      tasks: { keep.id => { content: "セブン銀行で交通費", category: "事務" }, move.id => { content: "戸籍" } },
      new: { content: "青いカバ", category: "趣味", estimate_minutes: "20" },
      move: { move.id => "today" }
    }
    assert_redirected_to tasks_path

    assert_equal "セブン銀行で交通費", keep.reload.content
    assert_equal "事務", keep.category
    assert_not_nil move.reload.date
    assert_equal [ [ "青いカバ", "趣味", 20 ] ], Task.where.not(id: [ keep.id, move.id ]).pluck(:content, :category, :estimate_minutes)
  end

  test "inbox は今日から1週間を日ごとに見せ、日付を選んで移せる" do
    task = Task.create!(content: "戸籍")

    travel_to Time.zone.parse("2026-10-23 03:00") do
      patch tasks_path, params: { move: { task.id => "2026-10-26" } }
      get tasks_path
    end

    assert_equal Date.new(2026, 10, 26), task.reload.date
    assert_select "h2", text: /今日 10\/23 Fri/
    assert_select "h2", text: /明日 10\/24 Sat/
    assert_select "h2", count: 9
    assert_select "select[name='move[#{task.id}]'] option[value=?]", "2026-10-29"
  end

  test "log ページに今日のタスクとルーティンが出る" do
    list = PlannerList.create!(slug: "morning", title: "朝の準備", wdays: "0123456", category: "生活")
    list.planner_items.create!(content: "顔洗う")
    task = Task.create!(content: "輪講", date: Date.current)

    travel_to Time.zone.parse("#{Date.current} 12:00") do
      get log_path(Date.current.strftime("%Y%m%d"))
    end
    assert_select "#task_#{task.id} input[value=?]", "輪講"
    assert_select "#plan summary", text: "朝の準備"
    assert_select "#plan button[data-plan-category-param=?]", "生活"
    assert_select "#plan li", text: /顔洗う/
  end

  test "inbox で見積もりを入れると合計が出る" do
    a = Task.create!(content: "戸籍")
    b = Task.create!(content: "セブン銀行")

    patch tasks_path, params: { tasks: { a.id => { content: "戸籍", estimate_minutes: "30" }, b.id => { content: "セブン銀行", estimate_minutes: "45" } } }
    get tasks_path

    assert_select "h2", text: /inbox 1:15/
  end

  test "プロジェクトからタスクを足すと inbox に入る" do
    project = Project.create!(name: "卒論", category: "研究")

    post tasks_path, params: { from: "project", task: { content: "参考文献", project_id: project.id } }
    assert_redirected_to project_path(project)

    task = project.tasks.last
    assert_nil task.week
    assert_equal "研究", task.category
  end

  test "plan で欄を書き換えられる" do
    task = Task.create!(content: "掃除", date: Date.current)

    patch task_path(task), params: { task: { content: "風呂掃除", estimate_minutes: "25", category: "生活" } }
    assert_response :success
    assert_equal [ "風呂掃除", 25, "生活" ], task.reload.then { [ _1.content, _1.estimate_minutes, _1.category ] }

    patch task_path(task), params: { task: { content: "" } }
    assert_response :unprocessable_entity
  end

  test "plan から追加して消せる" do
    post tasks_path, params: { task: { content: "掃除", date: "2026-10-16" } }
    assert_response :success
    task = Task.last
    assert_equal Date.new(2026, 10, 16), task.date

    delete task_path(task)
    assert_not Task.exists?(task.id)
  end

  test "ルーティンの一覧でまとめて書き換え・追加できる" do
    list = PlannerList.create!(slug: "evening", title: "夜")

    patch planner_lists_path, params: {
      lists: { list.id => { title: "夜の支度", category: "生活", period: "夜", wdays: [ "", "1", "3" ] } },
      new: { title: "講義", period: "昼" }
    }
    assert_redirected_to planner_everyday_path

    list.reload
    assert_equal [ "夜の支度", "生活", "夜", "13" ], [ list.title, list.category, list.period, list.wdays ]

    get planner_everyday_path
    assert_select "input[value=?]", "講義"
  end

  test "ルーティンの中身を書き換え・追加・削除できる" do
    list = PlannerList.create!(title: "朝の準備")
    keep = list.planner_items.create!(content: "顔洗う")
    drop = list.planner_items.create!(content: "コーヒー")

    patch planner_list_path(list), params: { planner_list: { note: "早めに", planner_items_attributes: {
      "0" => { id: keep.id, content: "顔を洗う", condition: "" },
      "1" => { id: drop.id, content: "" },
      "2" => { content: "傘を持つ", condition: "rain" },
      "3" => { content: "" }
    } } }
    assert_redirected_to planner_list_path(list)

    assert_equal [ [ "顔を洗う", nil ], [ "傘を持つ", "rain" ] ], list.planner_items.reload.map { [ _1.content, _1.condition.presence ] }
    assert_equal "早めに", list.reload.note

    get planner_list_path(list)
    assert_select "input[value=?]", "傘を持つ"
  end

  test "過ぎた日のログには実際の可処分だけが式で出る" do
    Page.create!(date: "2026-10-12").records.create!(start_time: Time.zone.parse("2026-10-12 08:00"), end_time: Time.zone.parse("2026-10-12 24:00"), category: "研究")
    page = Page.create!(date: "2026-10-21")
    page.records.create!(start_time: Time.zone.parse("2026-10-21 08:00"), end_time: Time.zone.parse("2026-10-21 22:00"), category: "研究")
    page.records.create!(start_time: Time.zone.parse("2026-10-21 22:00"), end_time: Time.zone.parse("2026-10-21 24:00"), category: "娯楽/だらだら")

    get log_path("20261021")

    assert_select "p", text: /可処分 予定/, count: 0
    assert_select "p", text: /可処分 実際 14:00 = 16:00 − ↻ 0:00 − 2:00/
  end
end
