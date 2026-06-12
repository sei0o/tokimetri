morning = PlannerList.find_or_create_by!(slug: "morning") { |l| l.title = "朝" }
unless morning.planner_items.exists?
  [
    { content: "起きる", item_type: "task" },
    { content: "カーテンを開ける", item_type: "task" },
    { content: "なるべく早くコーヒーを入れる", item_type: "task" },
    { content: "顔洗う", item_type: "task" },
    { content: "日焼け止め塗る", item_type: "task" },
    { content: "飯食う", item_type: "task" },
    { content: "薬飲む", item_type: "task" },
    { content: "歯を磨く", item_type: "task" },
    { content: "週末の掃除", item_type: "task", condition: "saturday" },
  ].each_with_index do |attrs, i|
    morning.planner_items.create!(attrs.merge(position: i))
  end
end

leave_home = PlannerList.find_or_create_by!(slug: "leave_home") { |l| l.title = "出かける" }
unless leave_home.planner_items.exists?
  [
    { content: "ハンカチを持つ", item_type: "task" },
    { content: "着替える（昨日替えた靴下を履く）", item_type: "task" },
    { content: "傘を持つ", item_type: "task", condition: "rain" },
    { content: "カバンにものいれる（PC、財布、スマホ）", item_type: "task" },
  ].each_with_index do |attrs, i|
    leave_home.planner_items.create!(attrs.merge(position: i))
  end
end

evening = PlannerList.find_or_create_by!(slug: "evening") { |l| l.title = "夜" }
unless evening.planner_items.exists?
  [
    { content: "スマホの電源を落とす", item_type: "task" },
    { content: "掃除機かける (5min)", item_type: "task" },
    { content: "風呂に入る 20min", item_type: "task" },
    { content: "下着と靴下を変える", item_type: "task" },
    { content: "保湿をする（顔、脇、身体）", item_type: "task" },
    { content: "食事を作る・食べる 60min", item_type: "task" },
    { content: "明日の予定を確認する", item_type: "task" },
    { content: "歯を磨く", item_type: "task" },
    { content: "寝る", item_type: "task" },
    { content: "ゴミ出しは朝8時まで\n水 → 燃えるごみ\n木曜 → 古紙・プラスチック\n第1・3金 → 不燃ごみ・電池\n土曜 → 燃えるごみ・ビンカンPET", item_type: "note" },
  ].each_with_index do |attrs, i|
    evening.planner_items.create!(attrs.merge(position: i))
  end
end
