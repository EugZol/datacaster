module Datacaster
  class ContextNode < Base
    def initialize(base)
      @base = base
    end

    def cast(object, runtime:)
      runtime = create_runtime(runtime)
      result = @base.with_runtime(runtime).call(object)
      transform_result(result, runtime)
    end

    def to_json_schema
      @base.to_json_schema
    end

    def to_json_schema_attributes
      @base.to_json_schema_attributes
    end

    def inspect
      "#<#{self.class.name} base: #{@base.inspect}>"
    end

    private

    def create_runtime(parent)
      parent
    end

    def transform_result(result, runtime)
      if result.valid?
        Datacaster.ValidResult(transform_success(result.value, runtime))
      else
        Datacaster.ErrorResult(transform_errors(result.raw_errors, runtime))
      end
    end

    def transform_success(value, _runtime)
      value
    end

    def transform_errors(errors, _runtime)
      errors
    end
  end
end
