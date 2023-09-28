module Datacaster
  class Trier < Base
    def initialize(catched_exception, error_key = nil, &block)
      raise "Expected block" unless block_given?

      @catched_exception = Array(catched_exception)
      @try = block

      @error_keys = ['.try', 'datacaster.errors.try']
      @error_keys.unshift(error_key) if error_key
    end

    def cast(object, runtime:)
      begin
        Datacaster.ValidResult(Runtimes::Base.(runtime, @try, object))
      rescue *@catched_exception
        Datacaster.ErrorResult(I18nValues::Key.new(@error_keys, value: object))
      end
    end

    def inspect
      "#<Datacaster::Trier>"
    end
  end
end
