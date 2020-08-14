module Datacaster
  class OrNode < Base
    def initialize(left, right)
      @left = left
      @right = right
    end

    def call(object)
      object = super(object)

      left_result = @left.(object)

      return left_result if left_result.valid?

      @right.(object)
    end

    def inspect
      "#<Datacaster::OrNode L: #{@left.inspect} R: #{@right.inspect}>"
    end
  end
end
