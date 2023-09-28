module Datacaster
  class Checker < Base
    def initialize(error_key = nil, &block)
      raise "Expected block" unless block_given?

      @error_keys = ['.check', 'datacaster.errors.check']
      @error_keys.unshift(error_key) if error_key

      @check = block
    end

    def cast(object, runtime:)
      if Runtimes::Base.(runtime, @check, object)
        Datacaster.ValidResult(object)
      else
        Datacaster.ErrorResult(I18nValues::Key.new(@error_keys, value: object))
      end
    end

    def inspect
      "#<Datacaster::Checker>"
    end
  end
end
