module Datacaster
  class ArraySchema < Base
    def initialize(element_caster)
      # support of shortcut nested validation definitions, e.g. array_schema({a: [integer], b: {c: integer}})
      @element_caster = shortcut_definition(element_caster)
    end

    def call(object)
      object = super(object)
      checked_schema = object.meta[:checked_schema] || []

      array = object.value

      return Datacaster.ErrorResult(["must be array"]) if !array.respond_to?(:map) || !array.respond_to?(:zip)
      return Datacaster.ErrorResult(["must not be empty"]) if array.empty?

      result =
        array.zip(checked_schema).map do |x, schema|
          x = Datacaster.ValidResult(x, meta: {checked_schema: schema})
          @element_caster.(x)
        end

      if result.all?(&:valid?)
        checked_schema = result.map { |x| x.meta[:checked_schema] }
        Datacaster.ValidResult(result.map(&:value), meta: {checked_schema: checked_schema})
      else
        Datacaster.ErrorResult(result.each.with_index.reject { |x, _| x.valid? }.map { |x, i| [i, x.errors] }.to_h)
      end
    end

    def inspect
      "#<Datacaster::ArraySchema [#{@element_caster.inspect}]>"
    end
  end
end
