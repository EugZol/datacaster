module Datacaster
  class Checker < Base
    def initialize(name, error, &block)
      raise "Expected block" unless block_given?

      @name = name
      @error = error
      @check = block
    end

    def call(object)
      intermediary_result = super(object)
      object = intermediary_result.value

      if @check.(object)
        Datacaster.ValidResult(object)
      else
        Datacaster.ErrorResult([@error])
      end
    end

    def inspect
      "#<Datacaster::#{@name}Checker>"
    end
  end
end
