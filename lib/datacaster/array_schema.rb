module Datacaster
  class ArraySchema < Base
    def initialize(element_caster, error_keys = {}, allow_empty: true)
      @element_caster = element_caster
      @allow_empty = allow_empty

      @not_array_error_keys = ['.array', 'datacaster.errors.array']
      @not_array_error_keys.unshift(error_keys[:array]) if error_keys[:array]

      @empty_error_keys = ['.empty', 'datacaster.errors.empty']
      @error_keys.unshift(error_keys[:empty]) if error_keys[:empty]
    end

    def cast(array, runtime:)
      return Datacaster.ErrorResult(I18nValues::Key.new(@not_array_error_keys, value: array)) if !array.respond_to?(:map) || !array.respond_to?(:zip)
      return Datacaster.ErrorResult(I18nValues::Key.new(@empty_error_keys, value: array)) if array.empty? && !@allow_empty

      runtime.will_check!

      result =
        array.map.with_index do |x, i|
          runtime.checked_key!(i) do
            @element_caster.with_runtime(runtime).(x)
          end
        end

      if result.all?(&:valid?)
        Datacaster.ValidResult(result.map!(&:value))
      else
        Datacaster.ErrorResult(result.each.with_index.reject { |x, _| x.valid? }.map { |x, i| [i, x.raw_errors] }.to_h)
      end
    end

    def to_json_schema
      JsonSchemaResult.new({
        'type' => 'array',
        'items' => @element_caster.to_json_schema
      })
    end

    def inspect
      "#<Datacaster::ArraySchema [#{@element_caster.inspect}]>"
    end
  end
end
