module Datacaster
  class ThenNode < Base
    def initialize(left, then_caster, else_caster = nil)
      @left = left
      @then = then_caster
      @else = else_caster
    end

    def else(else_caster)
      raise ArgumentError.new("Datacaster: double else clause is not permitted") if @else

      self.class.new(@left, @then, else_caster)
    end

    def cast(object, runtime:)
      unless @else
        raise ArgumentError.new('Datacaster: use "a & b" instead of "a.then(b)" when there is no else-clause')
      end

      left_result = @left.with_runtime(runtime).(object)

      if left_result.valid?
        @then.with_runtime(runtime).(left_result.value)
      else
        @else.with_runtime(runtime).(object)
      end
    end

    def inspect
      "#<Datacaster::ThenNode Then: #{@then.inspect} Else: #{@else.inspect}>"
    end
  end
end
