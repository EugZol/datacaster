module Datacaster
  class Transformer < Base
    def initialize(&block)
      raise "Expected block" unless block_given?

      @transform = block
    end

    def cast(object, runtime:)
      result = Runtimes::Base.(runtime, @transform, object)
      if runtime.respond_to?(:will_not_check!)
        runtime.will_not_check!
      end
      Datacaster::ValidResult(result)
    end

    def inspect
      "#<Datacaster::Transformer>"
    end
  end
end
