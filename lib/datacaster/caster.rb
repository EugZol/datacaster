module Datacaster
  class Caster < Base
    def initialize(&block)
      raise "Expected block" unless block_given?

      @cast = block
    end

    def cast(object, runtime:)
      result = Runtimes::Base.(runtime, @cast, object)

      if defined?(Dry::Monads::Result) && result.is_a?(Dry::Monads::Result)
        result = result.success? ? Datacaster.ValidResult(result.value!) : Datacaster.ErrorResult(result.failure)
      end

      raise TypeError.new("Either Datacaster::Result or Dry::Monads::Result " \
        "should be returned from cast block, instead got #{result.inspect}") unless result.is_a?(Datacaster::Result)

      result
    end

    def inspect
      "#<Datacaster::Caster>"
    end
  end
end
