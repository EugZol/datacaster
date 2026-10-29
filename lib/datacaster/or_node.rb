module Datacaster
  class OrNode < Base
    def initialize(left, right)
      @left = left
      @right = right
    end

    def cast(object, runtime:)
      left_result = runtime.record_checks_on_success { @left.with_runtime(runtime).(object) }

      return left_result if left_result.valid?

      @right.with_runtime(runtime).(object)
    end

    def to_json_schema
      JsonSchemaResult.new({
        "anyOf" => [@left, @right].map(&:to_json_schema)
      })
    end

    def to_json_schema_attributes
      super.merge(
        required:
          @left.to_json_schema_attributes[:required] &&
            @right.to_json_schema_attributes[:required]
      )
    end

    def inspect
      "#<Datacaster::OrNode L: #{@left.inspect} R: #{@right.inspect}>"
    end
  end
end
