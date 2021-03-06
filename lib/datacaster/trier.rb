module Datacaster
  class Trier < Base
    def initialize(name, error, catched_exception, &block)
      raise "Expected block" unless block_given?

      @name = name
      @error = error
      @catched_exception = Array(catched_exception)
      @transform = block
    end

    def call(object)
      intermediary_result = super(object)
      object = intermediary_result.value

      begin
        Datacaster.ValidResult(@transform.(object))
      rescue *@catched_exception
        Datacaster.ErrorResult([@error])
      end
    end

    def inspect
      "#<Datacaster::#{@name}Trier>"
    end
  end
end
