module Datacaster
  class Transformer < Base
    def initialize(&block)
      raise "Expected block" unless block_given?

      @transform = block
    end

    def cast(object, runtime:)
      Datacaster.ValidResult(Runtimes::Base.(runtime, @transform, object))
    end

    def inspect
      "#<Datacaster::Transformer>"
    end
  end
end
