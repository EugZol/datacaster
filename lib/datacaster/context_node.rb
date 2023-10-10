module Datacaster
  class ContextNode < Base
    def initialize(base)
      @base = base
    end

    def cast(object, runtime:)
      @runtime = create_runtime(runtime)
      result = @base.with_runtime(@runtime).call(object)
      transform_result(result)
    end

    def to_json_schema
      @base.to_json_schema
    end

    def inspect
      "#<#{self.class.name} base: #{@base.inspect}>"
    end

    private

    def create_runtime(parent)
      parent
    end

    def runtime
      @runtime
    end

    def transform_result(result)
      if result.valid?
        Datacaster.ValidResult(transform_success(result.value))
      else
        Datacaster.ErrorResult(transform_errors(result.raw_errors))
      end
    end

    def transform_success(value)
      value
    end

    def transform_errors(errors)
      errors
    end
  end
end
