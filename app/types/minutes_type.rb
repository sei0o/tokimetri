# 長さを分で持つ。「1:30」も「90」も 90 分
class MinutesType < ActiveRecord::Type::Integer
  def cast_value(value)
    case value.to_s.strip
    when /\A(\d+):(\d{2})\z/ then $1.to_i * 60 + $2.to_i
    when /\A\d+\z/ then value.to_i
    end
  end
end
