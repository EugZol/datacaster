module Datacaster
  class ArraySchema < Base
    def initialize(element_caster)
      @element_caster = element_caster
    end

    def cast(array, runtime:)
      return Datacaster.ErrorResult(["must be array"]) if !array.respond_to?(:map) || !array.respond_to?(:zip)
      return Datacaster.ErrorResult(["must not be empty"]) if array.empty?

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
        Datacaster.ErrorResult(result.each.with_index.reject { |x, _| x.valid? }.map { |x, i| [i, x.errors] }.to_h)
      end
    end

    def inspect
      "#<Datacaster::ArraySchema [#{@element_caster.inspect}]>"
    end
  end
end
