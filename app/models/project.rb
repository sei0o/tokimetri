# 所属は records.project_id で決まる。フィルタは、まだどこにも属していない行を拾うためのもの
class Project < ApplicationRecord
  has_many :records, dependent: :nullify
  has_many :tasks, -> { ordered }, dependent: :nullify

  validates :name, presence: true

  after_save :claim_matching

  def self.matching(record) = all.find { _1.matches?(record) }

  def terms = query.to_s.split

  def matches?(record)
    record.activity? && terms.any? { record.what.to_s.include?(_1) }
  end

  def minutes = records.sum { _1.duration_minutes.to_i }

  def add_term(term)
    update(query: [ *terms, term.strip ].uniq.join(" "))
  end

  def add(records)
    records.each { _1.update!(project: self) }
  end

  private

  def claim_matching
    unless terms.empty?
      add(Record.activities.where(project_id: nil)
                .where(Array.new(terms.size, "what LIKE ?").join(" OR "), *terms.map { "%#{Record.sanitize_sql_like(_1)}%" }))
    end
    records.update_all(category: category) if category.present?
  end
end
