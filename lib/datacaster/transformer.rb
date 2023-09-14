module Datacaster
  class Transformer < Base
    def initialize(name, &block)
      raise "Expected block" unless block_given?

      @name = name
      @transform = block
    end

    def cast(object, runtime:)
      Datacaster.ValidResult(Runtime.(runtime, @transform, object))
    end

    def inspect
      "#<Datacaster::#{@name}Transformer>"
    end
  end
end
