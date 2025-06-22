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
    return [] if self[:categories].blank?

    self[:categories].split("\n").map do |line|
      name, color = line.split(",")
      { name: name.strip, color: color.strip }
    end
  end

end
