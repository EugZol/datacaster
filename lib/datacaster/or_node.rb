module Datacaster
  class OrNode < Base
    def initialize(left, right)
      @left = left
      @right = right
    end

    def cast(object, runtime:)
      left_result = @left.with_runtime(runtime).(object)

      return left_result if left_result.valid?

      @right.with_runtime(runtime).(object)
    end

    def inspect
      "#<Datacaster::OrNode L: #{@left.inspect} R: #{@right.inspect}>"
    end
  end
end
