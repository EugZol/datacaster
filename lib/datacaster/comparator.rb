module Datacaster
  class Comparator < Base
    def initialize(value)
      @value = value
    end

    def cast(object, runtime:)
      if @value == object
        Datacaster.ValidResult(object)
      else
        Datacaster.ErrorResult(
          I18nValues::DefaultKeys.new(['.compare', 'datacaster.errors.compare'], reference: @value.inspect, value: object)
        )
      end
    end

    def inspect
      "#<Datacaster::Comparator>"
    end
  end
end
