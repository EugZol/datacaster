module Datacaster
  class Transformer < Base
    def initialize(&block)
      raise "Expected block" unless block_given?

      @transform = block
    end

    def cast(object, runtime:)
      result = Runtimes::Base.(runtime, @transform, object)
      if runtime.respond_to?(:checked_key!) && result.is_a?(Hash)
        result.keys.each { |key| runtime.checked_key!(key) }
      end
      Datacaster::ValidResult(result)
    end

    def inspect
      "#<Datacaster::Transformer>"
    end
  end
end
