module Datacaster
  class Caster < Base
    def initialize(&block)
      raise "Expected block" unless block_given?

      @cast = block
    end

    def cast(object, runtime:)
      result = Runtime.(runtime, @cast, object)

      raise TypeError.new("Either Datacaster::Result or Dry::Monads::Result " \
        "should be returned from cast block") unless [Datacaster::Result, Dry::Monads::Result].any? { |k| result.is_a?(k) }

      if result.is_a?(Dry::Monads::Result)
        result = result.success? ? Datacaster.ValidResult(result.value!) : Datacaster.ErrorResult(result.failure)
      end

      result
    end

    def inspect
      "#<Datacaster::Caster>"
    end
  end
end
