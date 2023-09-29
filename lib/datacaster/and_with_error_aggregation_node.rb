module Datacaster
  class AndWithErrorAggregationNode < Base
    def initialize(left, right)
      @left = left
      @right = right
    end

    # Works like AndNode, but doesn't stop at first error — in order to aggregate all Failures
    # Makes sense only for Hash Schemas
    def cast(object, runtime:)
      left_result = @left.with_runtime(runtime).(object)

      if left_result.valid?
        @right.with_runtime(runtime).(left_result.value)
      else
        right_result = @right.with_runtime(runtime).(object)
        if right_result.valid?
          left_result
        else
          Datacaster.ErrorResult(self.class.merge_errors(left_result.raw_errors, right_result.raw_errors))
        end
      end
    end

    def inspect
      "#<Datacaster::AndWithErrorAggregationNode L: #{@left.inspect} R: #{@right.inspect}>"
    end
  end
end
