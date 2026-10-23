require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in
    @project = Project.create!(name: "卒論", category: "研究")
    page = Page.create!(date: "2026-10-20")
    start = Time.zone.parse("2026-10-20 10:00")
    @record = page.records.create!(what: "レポート書く", category: "趣味", start_time: start, end_time: start + 90.minutes)
  end

  test "検索した語をフィルタに足すと、その行が記録に出る" do
    get search_path(q: "レポート")
    assert_select "form#assign"
    assert_select "input[name='record_ids[]'][form=assign]"

    post terms_projects_path, params: { project_id: @project.id, term: "レポート" }
    assert_redirected_to project_path(@project)

    get project_path(@project)
    assert_select "td", text: "1:30"
    assert_select "td", text: "レポート書く"
  end

  test "検索画面で選んだ行を入れ、プロジェクトの画面で外す" do
    post records_projects_path, params: { project_id: @project.id, record_ids: [ @record.id ] }
    assert_equal @project, @record.reload.project

    patch project_path(@project), params: { remove: [ @record.id ] }
    assert_nil @record.reload.project
  end

  test "一覧でまとめて書き換え・追加・削除できる" do
    gone = Project.create!(name: "引っ越し")

    patch projects_path, params: {
      projects: { @project.id => { name: "卒論", category: "研究", query: "レポート" }, gone.id => { name: "" } },
      new: { name: "発表", category: "研究" }
    }
    assert_redirected_to projects_path

    assert_equal "レポート", @project.reload.query
    assert_equal [ "卒論", "発表" ], Project.order(:name).pluck(:name).sort
    assert_equal @project, @record.reload.project

    get projects_path
    assert_select "input[value=?]", "発表"
  end

  test "候補からルーティンにできる" do
    post planner_lists_path, params: { planner_list: { title: "シャワー", category: "生活", estimate_minutes: 20, wdays: [ 1, 3 ] } }
    assert_redirected_to planner_everyday_path

    assert_equal [ "シャワー", "13", 20 ], PlannerList.last.then { [ _1.title, _1.wdays, _1.estimate_minutes ] }
  end
end
