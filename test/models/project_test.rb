require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    @page = Page.create!(date: "2026-10-20")
  end

  def record(what, category = "趣味", minutes = 30)
    start = Time.zone.parse("2026-10-20 10:00")
    @page.records.create!(what: what, category: category, start_time: start, end_time: start + minutes.minutes)
  end

  test "フィルタに当たる新しい行はプロジェクトに入り、カテゴリが揃う" do
    project = Project.create!(name: "卒論", category: "研究", query: "レポート 輪講")

    hit = [ record("レポート書く"), record("輪講準備", "研究", 60) ]
    miss = record("YouTube", "娯楽/だらだら")

    assert_equal hit.map(&:id).sort, project.records.pluck(:id).sort
    assert_equal %w[研究 研究], hit.map(&:category)
    assert_equal "娯楽/だらだら", miss.category
    assert_equal 90, project.minutes
  end

  test "あとから足した語や選んだ行も入る" do
    old = record("スライド作る")
    other = record("図を作る")
    project = Project.create!(name: "発表", category: "研究")

    project.add_term("スライド")
    project.add([ other ])

    assert_equal "スライド", project.query
    assert_equal [ old, other ].map(&:id).sort, project.records.pluck(:id).sort
    assert_equal "研究", old.reload.category
  end

  test "外した行は、書き換えない限りフィルタで戻らない" do
    project = Project.create!(name: "卒論", query: "レポート")
    row = record("レポート書く")

    row.update!(project: nil)
    row.update!(end_time: row.end_time + 10.minutes)

    assert_nil row.reload.project_id
  end

  test "解析し直してもプロジェクトに入れた行は残る" do
    project = Project.create!(name: "卒論")
    project.add([ record("図を作る") ])

    @page.apply_parsed_records([ { "start" => "2026-10-20 10:00", "end" => "2026-10-20 10:40", "what" => "図を描く", "category" => "研究" } ])

    assert_equal [ "図を描く" ], project.records.pluck(:what)
  end
end
