module Datacaster
  class JsonSchemaNode < Base
    def initialize(base, schema_attributes = {}, &block)
      @base = base
      @schema_attributes = schema_attributes.transform_keys(&:to_s)
      @block = block
    end

    def cast(object, runtime:)
      @base.cast(object, runtime: runtime)
    end

    def to_json_schema
      result = @base.to_json_schema
      result = result.apply(@schema_attributes)
      result = @block.(result) if @block
      result
    end

    def inspect
      "#<#{self.class.name} base: #{@base.inspect}>"
    end
  end
end
