class Setting < ApplicationRecord
  def self.instance
    first_or_create!
  end

  def prompt
    return "" if self[:prompt].blank?
    self[:prompt].strip
  end

  def categories
    {
      "睡眠" => "#3c4c5d",
      "事務" => "#2d8a44",
      "研究" => "#4175c9",
      "講義" => "#13634b",
      "趣味" => "#c43dad", # 読書、絵を描く, tokimetri開発, お菓子作り, ゲーム(ソシャゲ以外), ブログ執筆
      "娯楽/だらだら" => "#eb0348", # ぼーっとする、ネットサーフィン、YouTube、, ソシャゲ
      "生活" => "#46843e", # 週次レビュー
      "仕事" => "#357e9e",
      "移動" => "#6e6e6e"
    }
  end
end
