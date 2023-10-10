module Datacaster
  class HashMapper < Base
    def initialize(fields)
      keys = fields.keys.flatten
      if keys.length != keys.uniq.length
        intersection = keys.select { |k| keys.count(k) > 1 }.uniq.sort
        raise ArgumentError.new("When using transform_to_hash([:a, :b, :c] => validator), " \
          "each key should not be mentioned more than once on the left-hand-side. Instead, got these " \
          "keys mentioned twice or more: #{intersection.inspect}."
        )
      end

      @fields = fields
    end

    def cast(object, runtime:)
      errors = {}
      result = {}

      runtime.will_check!

      @fields.each do |key, validator|
        new_value = runtime.ignore_checks! { validator.with_runtime(runtime).(object) }

        # transform_to_hash([:a, :b, :c] => pick(:a, :b, :c) & ...)
        if key.is_a?(Array)
          unwrapped = new_value.valid? ? new_value.value : new_value.raw_errors

          if key.length != unwrapped.length
            raise TypeError, "When using transform_to_hash([:a, :b, :c] => validator), validator should return Array "\
              "with number of elements equal to the number of elements in left-hand-side array.\n" \
              "Got the following (values or errors) instead: #{key.inspect} => #{unwrapped.inspect}."
          end
        end

        if new_value.valid?
          if key.is_a?(Array)
            key.zip(new_value.value) do |new_key, new_key_value|
              result[new_key] = new_key_value
              runtime.checked_key!(new_key)
            end
          else
            result[key] = new_value.value
            runtime.checked_key!(key)
          end
        else
          if key.is_a?(Array)
            errors = Utils.merge_errors(errors, key.zip(new_value.raw_errors).to_h)
          else
            errors = Utils.merge_errors(errors, {key => new_value.raw_errors})
          end
        end
      end

      errors.delete_if { |_, v| v.empty? }

      if errors.empty?
        # All unchecked key-value pairs of initial hash are passed through, and eliminated by ContextNode
        # at the end of the chain. If we weren't dealing with the hash, then ignore that.
        result_hash =
          if object.is_a?(Hash)
            object.merge(result)
          else
            result
          end

        result_hash.keys.each { |k| result_hash.delete(k) if result_hash[k] == Datacaster.absent }
        Datacaster.ValidResult(result_hash)
      else
        Datacaster.ErrorResult(errors)
      end
    end

    def to_json_schema
      @fields.values.reduce(JsonSchemaResult.new) do |result, caster|
        result.apply(caster.to_json_schema)
      end
    end

    def inspect
      field_descriptions =
        @fields.map do |k, v|
          "#{k.inspect} => #{v.inspect}"
        end

      "#<Datacaster::HashMapper {#{field_descriptions.join(', ')}}>"
    end
  end
end
