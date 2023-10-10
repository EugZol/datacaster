module Datacaster
  class HashSchema < Base
    def initialize(fields, error_key = nil)
      @fields = fields

      @error_keys = ['.hash_value', 'datacaster.errors.hash_value']
      @error_keys.unshift(error_key) if error_key
    end

    def cast(object, runtime:)
      return Datacaster.ErrorResult(I18nValues::Key.new(@error_keys, value: object)) unless object.is_a?(Hash)

      runtime.will_check!

      errors = {}
      result = {}

      @fields.each do |key, validator|
        value =
          if object.key?(key)
            object[key]
          else
            Datacaster.absent
          end

        new_value = runtime.checked_key!(key) { validator.with_runtime(runtime).(value) }
        if new_value.valid?
          result[key] = new_value.value
        else
          errors[key] = new_value.raw_errors
        end
      end

      if errors.empty?
        # All unchecked key-value pairs are passed through, and eliminated by ContextNode
        # at the end of the chain
        result_hash = object.merge(result)
        result_hash.keys.each { |k| result_hash.delete(k) if result_hash[k] == Datacaster.absent }
        Datacaster.ValidResult(result_hash)
      else
        Datacaster.ErrorResult(errors)
      end
    end

    def to_json_schema
      JsonSchemaResult.new({
        "type" => "object",
        "properties" => @fields.map { |k, v| [k.to_s, v.to_json_schema] }.to_h,
        "required" => @fields.keys.map(&:to_s)
      })
    end

    def inspect
      field_descriptions =
        @fields.map do |k, v|
          "#{k.inspect} => #{v.inspect}"
        end

      "#<Datacaster::HashSchema {#{field_descriptions.join(', ')}}>"
    end
  end
end
