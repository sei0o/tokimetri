class Record < ApplicationRecord
  belongs_to :page

  enum :kind, { activity: "activity", note: "note" }

  scope :activities, -> { where(kind: "activity") }

  # これ未満は当たらないので何も返さない
  SIMILARITY = 0.8

  def duration_minutes
    return nil unless start_time
    return nil unless end_time

    ((end_time - start_time) / 60).to_i
  end

  # 過去に書いたものから、文字bigramが近いものを探してカテゴリを引く
  def self.guess_category(text)
    target = bigrams(text)
    return if target.empty?

    score, _, category = known_categories.map { |what, cat, count|
      [ dice(target, bigrams(what)), count, cat ]
    }.max

    category if score && score >= SIMILARITY
  end

  def self.known_categories
    activities.where.not(category: [ nil, "" ]).where.not(what: [ nil, "" ])
              .group(:what, :category).count
              .map { |(what, category), count| [ what, category, count ] }
  end

  def self.bigrams(text)
    word = text.to_s.downcase.gsub(/\s+/, "")
    return Set.new if word.empty?
    return Set[word] if word.length == 1

    (0...word.length - 1).map { |i| word[i, 2] }.to_set
  end

  def self.dice(a, b)
    2.0 * (a & b).size / (a.size + b.size)
  end

  private_class_method :known_categories, :bigrams, :dice
end
