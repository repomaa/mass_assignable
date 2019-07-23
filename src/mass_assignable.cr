require "./mass_assignable/from_attribute"
require "./mass_assignable/to_attribute"

module MassAssignable
  VERSION = "0.1.0"

  annotation Field
  end

  macro included
    def self.new(**attributes)
      instance = allocate
      instance.initialize(__mass_assign_attributes: attributes)
      GC.add_finalizer(instance) if instance.responds_to?(:finalize)
      instance
    end

    def self.from_attribute(attributes : NamedTuple)
      new(**attributes)
    end
  end

  def initialize(*, __mass_assign_attributes attributes : T) forall T
    {% begin %}
      {% properties = {} of Nil => Nil %}
      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(::MassAssignable::Field) %}
        {%
          properties[ivar.id] = {
            type:        ivar.type,
            key:         ((ann && ann[:key]) || ivar).id.symbolize,
            has_default: ivar.has_default_value?,
            default:     ivar.default_value,
            nilable:     ivar.type.nilable?,
            root:        ann && ann[:root],
            converter:   ann && ann[:converter],
            presence:    ann && ann[:presence],
            found:       false,
            ignore:      ann && ann[:ignore],
          }
        %}
      {% end %}

      {% for name, value in properties %}
        %var{name} = nil
      {% end %}

      {% for key, type in T %}
        {% key = key.symbolize %}
        {% unless properties.values.any? { |options| key == options[:key] } %}
          {% raise "Unknown key #{key}" %}
        {% end %}

        {% for name, options in properties %}
          {% if !options[:ignore] && key == options[:key] %}
            {% options[:found] = true %}
            %var{name} = begin
              {% if options[:root] %}
                value = attributes[{{key}}][:{{options[:root].id}}]
              {% else %}
                value = attributes[{{key}}]
              {% end %}

              {% if options[:converter] %}
                {{options[:converter]}}.from_attribute(value)
              {% else %}
                ::Union({{options[:type]}}).from_attribute(value)
              {% end %}
            end
          {% end %}
        {% end %}
      {% end %}

      {% for name, options in properties %}
        {% unless options[:ignore] %}
          {% if options[:nilable] %}
            {% if options[:has_default] != nil %}
              @{{name}} =
                {% if options[:found] %}
                  %var{name}
                {% else %}
                  {{options[:default]}}
                {% end %}
            {% else %}
              @{{name}} = %var{name}
            {% end %}
          {% elsif options[:has_default] %}
            @{{name}} = %var{name}.nil? ? {{options[:default]}} : %var{name}
          {% else %}
            @{{name}} = (%var{name}).as({{options[:type]}})
          {% end %}
        {% end %}

        {% if options[:presence] %}
          @{{name}}_present = {{options[:found]}}
        {% end %}
      {% end %}
    {% end %}
  end

  def to_attribute
    {% begin %}
      {% properties = {} of Nil => Nil %}
      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(::MassAssignable::Field) %}
        {% unless ann && ann[:ignore] %}
          {%
            properties[ivar.id] = {
              type:      ivar.type,
              key:       ((ann && ann[:key]) || ivar).id,
              root:      ann && ann[:root],
              converter: ann && ann[:converter],
              ignore:    ann && ann[:ignore],
            }
          %}
        {% end %}
      {% end %}

      {% for name, options in properties %}
        {% unless options[:ignore] %}
          %value{name} = @{{name}}.to_attribute

          {% if options[:converter] %}
            %value{name} = {{options[:converter]}}.to_attribute(%value{name})
          {% end %}

          {% if options[:root] %}
            %value{name} = { {{options[:root].id}}: %value{name} }
          {% end %}
        {% end %}
      {% end %}

      {
        {% for name, options in properties %}
          {% unless options[:ignore] %}
            {{options[:key]}}: %value{name},
          {% end %}
        {% end %}
      }
    {% end %}
  end

  def attributes=(attributes : NamedTuple)
    assign_attributes(**attributes)
  end

  private def assign_attributes(**attributes : **T) forall T
    {% begin %}
      {% properties = {} of Nil => Nil %}
      {% for ivar in @type.instance_vars %}
        {% ann = ivar.annotation(::MassAssignable::Field) %}
        {%
          properties[ivar.id] = {
            type:      ivar.type,
            key:       ((ann && ann[:key]) || ivar).id.symbolize,
            root:      ann && ann[:root],
            converter: ann && ann[:converter],
            ignore:    ann && ann[:ignore],
          }
        %}
      {% end %}

      {% for key, type in T %}
        {% key = key.symbolize %}
        {% unless properties.values.any? { |options| key == options[:key] } %}
          {% raise "Unknown key #{key}" %}
        {% end %}

        {% for name, options in properties %}
          {% if !options[:ignore] && key == options[:key] %}
            self.{{name}} = begin
              {% if options[:root] %}
                value = attributes[{{key}}][:{{options[:root].id}}]
              {% else %}
                value = attributes[{{key}}]
              {% end %}

              {% if options[:converter] %}
                {{options[:converter]}}.from_attribute(value)
              {% else %}
                ::Union({{options[:type]}}).from_attribute(value)
              {% end %}
            end
          {% end %}
        {% end %}
      {% end %}
    {% end %}

    self
  end

  macro inherited
    def self.new(**attributes)
      super
    end
  end
end
