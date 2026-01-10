class Setting < ApplicationRecord
  def self.instance
    first_or_create!
  end

  def prompt
    return '' if self[:prompt].blank?
    self[:prompt].strip
  end

  # カテゴリは name,color(#rrggbb) のペアが\n区切りで複数入っている
  def categories
    # return [] if self[:categories].blank?

    # self[:categories].split("\n").map do |line|
    #   name, color = line.split(",")
    #   { name: name.strip, color: color.strip }
    # end
    {
      '睡眠' => '#3c4c5d',
      '事務' => '#2d8a44',
      '研究' => '#4175c9',
      '趣味' => '#c43dad',
      'だらだら' => '#eb0348',
      '娯楽' => '#b16128',
      '生活' => '#46843e',
      '仕事' => '#357e9e',
      '移動' => '#6e6e6e',
    }
  end

end
