class GarbageSource
  def initialize(date:)
    @date = date
  end

  def tasks
    today = garbage_for(@date)
    tomorrow = garbage_for(@date + 1)

    items = []
    items << { content: today[:label], condition: nil, source: :garbage } if today
    unless tomorrow.nil? || tomorrow[:morning_only]
      items << { content: "明日の#{tomorrow[:label]}", condition: nil, source: :garbage_tomorrow }
    end
    items
  end

  private

  def garbage_for(date)
    case date.wday
    when 3 then { label: "燃えるごみを出す", morning_only: true }
    when 4 then { label: "古紙・プラスチックを出す", morning_only: false }
    when 5 then garbage_for_friday(date)
    when 6 then { label: "燃えるごみ・ビンカンPETを出す", morning_only: false }
    end
  end

  def garbage_for_friday(date)
    nth = ((date.day - 1) / 7) + 1
    return unless [ 1, 3 ].include?(nth)
    { label: "不燃ごみ・電池ごみを出す", morning_only: false }
  end
end
