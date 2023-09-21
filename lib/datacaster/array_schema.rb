module Datacaster
  class ArraySchema < Base
    def initialize(element_caster)
      @element_caster = element_caster
    end

    def cast(array, runtime:)
      return Datacaster.ErrorResult(I18nValues::DefaultKeys.new(['.array', 'datacaster.errors.array'], value: array)) if !array.respond_to?(:map) || !array.respond_to?(:zip)
      return Datacaster.ErrorResult(I18nValues::DefaultKeys.new(['.empty', 'datacaster.errors.empty'], value: array)) if array.empty?

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

    def inspect
      "#<Datacaster::ArraySchema [#{@element_caster.inspect}]>"
    end
  end
end
