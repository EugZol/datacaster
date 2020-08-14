module Datacaster
  class AndNode < Base
    def initialize(left, right)
      @left = left
      @right = right
    end

    def call(object)
      object = super(object)

      left_result = @left.(object)

      return left_result unless left_result.valid?

      @right.(left_result)
    end

    def inspect
      "#<Datacaster::AndNode L: #{@left.inspect} R: #{@right.inspect}>"
    end
  end
end
