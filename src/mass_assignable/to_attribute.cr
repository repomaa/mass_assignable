class Object
  def to_attribute
    self
  end
end

module Enumerable
  def to_attribute
    map(&.to_attribute)
  end
end

struct NamedTuple
  def to_attribute
    {% begin %}
      {
      {% for key, type in T %}
        {{key}}: self[{{key.symbolize}}].to_attribute,
      {% end %}
      }
    {% end %}
  end
end

class Hash
  def to_attribute
    transform_values do |value|
      value.to_attribute
    end
  end
end

struct StaticArray
  def to_attribute
    {% begin %}
      {
      {% for index in 0...N %}
        self[{{index}}].to_attribute,
      {% end %}
      }
    {% end %}
  end
end
