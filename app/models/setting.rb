class Setting < ApplicationRecord
  serialize :categories, coder: JSON

  DEFAULT_CATEGORIES = {
    "睡眠" => "#3c4c5d",
    "事務" => "#2d8a44",
    "研究" => "#4175c9",
    "講義" => "#13634b",
    "趣味" => "#c43dad",
    "娯楽/だらだら" => "#eb0348",
    "生活" => "#46843e",
    "仕事" => "#357e9e",
    "移動" => "#6e6e6e"
  }.freeze

  def self.instance
    first_or_create!
  end

  def prompt
    return "" if self[:prompt].blank?
    self[:prompt].strip
  end

  def categories
    super.presence || DEFAULT_CATEGORIES
  end

  # フォームから [{name, color}, ...] の配列で来るのをハッシュに変換
  def categories=(value)
    if value.is_a?(Array)
      super(value.each_with_object({}) { |v, h| h[v["name"]] = v["color"] if v["name"].present? })
    else
      super
    end
  end
end
