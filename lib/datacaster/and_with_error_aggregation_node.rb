module Datacaster
  class AndWithErrorAggregationNode < Base
    def initialize(left, right)
      @left = left
      @right = right
    end

    # Works like AndNode, but doesn't stop at first error — in order to aggregate all Failures
    # Makes sense only for Hash Schemas
    def call(object)
      object = super(object)

      left_result = @left.(object)

      if left_result.valid?
        @right.(left_result)
      else
        right_result = @right.(object)
        if right_result.valid?
          left_result
        else
          Datacaster.ErrorResult(self.class.merge_errors(left_result.errors, right_result.errors))
        end
      end
    end

    def inspect
      "#<Datacaster::AndWithErrorAggregationNode L: #{@left.inspect} R: #{@right.inspect}>"
    end
  end
end
