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
      new: [ "青いカバ", "" ],
      move: { move.id => "today" }
    }
    assert_redirected_to tasks_path

    assert_equal "セブン銀行で交通費", keep.reload.content
    assert_equal "事務", keep.category
    assert_not_nil move.reload.date
    assert_equal [ "青いカバ" ], Task.where.not(id: [ keep.id, move.id ]).pluck(:content)
  end

  test "log ページに今日のタスクとルーティンが出る" do
    list = PlannerList.create!(slug: "morning", title: "朝の準備", daily: true, category: "生活")
    list.planner_items.create!(content: "顔洗う")
    task = Task.create!(content: "輪講", date: Date.current)

    travel_to Time.zone.parse("#{Date.current} 12:00") do
      get log_path(Date.current.strftime("%Y%m%d"))
    end
    assert_select "#task_#{task.id}", text: /輪講/
    assert_select "#plan summary", text: "朝の準備"
    assert_select "#plan button[data-plan-category-param=?]", "生活"
    assert_select "#plan li", text: /顔洗う/
  end

  test "plan から追加して消せる" do
    post tasks_path, params: { task: { content: "掃除", date: "2026-10-16" } }
    assert_response :success
    task = Task.last
    assert_equal Date.new(2026, 10, 16), task.date

    delete task_path(task)
    assert_not Task.exists?(task.id)
  end

  test "planner のリストの名前とカテゴリを変えられる" do
    list = PlannerList.create!(slug: "evening", title: "夜")

    patch planner_list_path(list), params: { planner_list: { title: "夜の支度", category: "生活", daily: "1" } }
    assert_redirected_to planner_everyday_path

    list.reload
    assert_equal [ "夜の支度", "生活", true ], [ list.title, list.category, list.daily ]
  end
end
