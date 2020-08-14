module Datacaster
  class ThenNode < Base
    def initialize(left, then_caster)
      @left = left
      @then = then_caster
    end

    def else(else_caster)
      raise ArgumentError.new('Datacaster: double else clause is not permitted') if @else

      @else = else_caster
      self
    end

    def call(object)
      unless @else
        raise ArgumentError.new('Datacaster: use "a & b" instead of "a.then(b)" when there is no else-clause')
      end

      object = super(object)

      left_result = @left.(object)

      if left_result.valid?
        @then.(left_result)
      else
        @else.(object)
      end
    end

    def inspect
      "#<Datacaster::ThenNode Then: #{@then.inspect} Else: #{@else.inspect}>"
    end
  end
end
