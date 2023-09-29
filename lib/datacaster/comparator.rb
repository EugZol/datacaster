module Datacaster
  class Comparator < Base
    def initialize(value, error_key = nil)
      @value = value

      @error_keys = ['.compare', 'datacaster.errors.compare']
      @error_keys.unshift(error_key) if error_key
    end

    def cast(object, runtime:)
      if @value == object
        Datacaster.ValidResult(object)
      else
        Datacaster.ErrorResult(
          I18nValues::Key.new(@error_keys, reference: @value.inspect, value: object)
        )
      end
    end

    def inspect
      "#<Datacaster::Comparator>"
    end
  end
end
