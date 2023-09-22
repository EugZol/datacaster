module Datacaster
  class Trier < Base
    def initialize(catched_exception, &block)
      raise "Expected block" unless block_given?

      @catched_exception = Array(catched_exception)
      @transform = block
    end

    def cast(object, runtime:)
      begin
        Datacaster.ValidResult(Runtimes::Base.(runtime, @transform, object))
      rescue *@catched_exception
        Datacaster.ErrorResult(I18nValues::DefaultKeys.new(['.try', 'datacaster.errors.try'], value: object))
      end
    end

    def inspect
      "#<Datacaster::Trier>"
    end
  end
end
