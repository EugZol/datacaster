module Datacaster
  class Comparator < Base
    def initialize(value, name, error = nil)
      @value = value
      @name = name
      @error = error || "must be equal to #{value.inspect}"
    end

    def cast(object, runtime:)
      if @value == object
        Datacaster.ValidResult(object)
      else
        Datacaster.ErrorResult([@error])
      end
    end

    def inspect
      "#<Datacaster::#{@name}Comparator>"
    end
  end
end
