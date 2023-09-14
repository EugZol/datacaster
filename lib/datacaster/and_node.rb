module Datacaster
  class AndNode < Base
    def initialize(left, right)
      @left = left
      @right = right
    end

    def cast(object, runtime:)
      left_result = @left.with_runtime(runtime).(object)
      return left_result unless left_result.valid?

      @right.with_runtime(runtime).(left_result.value)
    end

    def inspect
      "#<Datacaster::AndNode L: #{@left.inspect} R: #{@right.inspect}>"
    end
  end
end
