class Record < ApplicationRecord
  belongs_to :page

  def duration_minutes
    return nil unless start_time
    return nil unless end_time

    ((end_time - start_time) / 60).to_i
  end

end
