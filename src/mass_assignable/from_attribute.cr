def Object.from_attribute(value)
  value.as(self)
end

{% for klass in %w[Array Set] %}
  def {{klass.id}}.from_attribute(elements : Enumerable)
    new.tap do |instance|
      elements.each do |element|
        instance << \{{T}}.from_attribute(element)
      end
    end
  end
{% end %}

def StaticArray.from_attribute(value : Indexable)
  new do |index|
    {{T}}.from_attribute(value[index])
  end
end

def Tuple.from_attribute(value : Tuple)
  {% begin %}
    new(
      {% for type, index in T %}
        {{type}}.from_attribute(value[{{index}}]),
      {% end %}
    )
  {% end %}
end

def Tuple.from_attribute(value : Indexable)
  {% begin %}
    {% for type, index in T %}
      %value{index} = value[{{index}}]
      %coerced_value{index} = case %value{index}
      when {{type}} then %value{index}
      {% for coercible_type in type.class.methods.select(&.name.== "from_attribute").map(&.args.first.restriction) %}
      when {{coercible_type}} then {{type}}.from_attribute(%value{index})
      {% end %}
      else raise "Couldn't coerce #{%value{index}} into {{type}}"
      end
    {% end %}

    new(
      {% for type, index in T %}
        %coerced_value{index},
      {% end %}
    )
  {% end %}
end

def Tuple.from_attribute(value : Enumerable)
  from_attribute(value.to_a)
end

def NamedTuple.from_attribute(value : NamedTuple)
  {% begin %}
    new(
      {% for key, type in T %}
        {{key}}: {{type}}.from_attribute(value[{{key.symbolize}}]),
      {% end %}
    )
  {% end %}
end

def NamedTuple.from_attribute(attribute : Hash)
  {% begin %}
    from(Hash(String, Union({{T.values.splat}})).from_attribute(attribute))
  {% end %}
end

def Hash.from_attribute(attribute : NamedTuple)
  {% begin %}
    new.tap do |instance|
      attribute.each do |key, value|
        instance[{% if K == String %}key.to_s{% else %}key{% end %}] = {{V}}.from_attribute(value)
      end
    end
  {% end %}
end

def Hash.from_attribute(value : Hash)
  {% begin %}
    new.tap do |instance|
      value.each do |key, value|
        instance[{% if K == String %}key.to_s{% else %}key{% end %}] = {{V}}.from_attribute(value)
      end
    end
  {% end %}
end

def Union.from_attribute(value)
  {% begin %}
    case value
    {% for type in T %}
      when {{type}} then value.as(self)
    {% end %}
    {% for type in T %}
      {% for method in type.class.methods.select(&.name.== "from_attribute") %}
        when {{method.args.first.restriction}} then {{type}}.from_attribute(value.as({{method.args.first.restriction}})).as(self)
      {% end %}
    {% end %}
    else raise "Couldn't convert #{value.class} into #{self}"
    end
  {% end %}
end
