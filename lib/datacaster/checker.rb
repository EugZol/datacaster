module Datacaster
  class Checker < Base
    def initialize(&block)
      raise "Expected block" unless block_given?

      @check = block
    end

    def cast(object, runtime:)
      if Runtimes::Base.(runtime, @check, object)
        Datacaster.ValidResult(object)
      else
        Datacaster.ErrorResult(I18nValues::DefaultKeys.new(['.check', 'datacaster.errors.check'], value: object))
      end
    end

    def inspect
      "#<Datacaster::Checker>"
    end
  end
end
