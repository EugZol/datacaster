module Datacaster
  class Runner < Base
    def initialize(&block)
      raise "Expected block" unless block_given?

      @run = block
    end

    def cast(object, runtime:)
      Runtimes::Base.(runtime, @run, object)
      Datacaster.ValidResult(object)
    end

    def inspect
      "#<Datacaster::Runner>"
    end
  end
end
