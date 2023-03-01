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

    def cast(object)
      object = super(object)
      # return Datacaster.ErrorResult(["must be hash"]) unless object.value.is_a?(Hash)

      checked_schema = object.meta[:checked_schema].dup || {}

      errors = {}
      result = {}

      @fields.each do |key, validator|
        new_value = validator.(object)

        # transform_to_hash([:a, :b, :c] => pick(:a, :b, :c) & ...)
        if key.is_a?(Array)
          unwrapped = new_value.valid? ? new_value.value : new_value.errors

          if key.length != unwrapped.length
            raise TypeError.new("When using transform_to_hash([:a, :b, :c] => validator), validator should return Array "\
              "with number of elements equal to the number of elements in left-hand-side array.\n" \
              "Got the following (values or errors) instead: #{keys.inspect} => #{values_or_errors.inspect}.")
          end
        end

        if new_value.valid?
          if key.is_a?(Array)
            key.zip(new_value.value) do |new_key, new_key_value|
              result[new_key] = new_key_value
              checked_schema[new_key] = true
            end
          else
            result[key] = new_value.value
            checked_schema[key] = true
          end
        else
          if key.is_a?(Array)
            errors = self.class.merge_errors(errors, key.zip(new_value.errors).to_h)
          else
            errors = self.class.merge_errors(errors, {key => new_value.errors})
          end
        end
      end

      errors.delete_if { |_, v| v.empty? }

      if errors.empty?
        # All unchecked key-value pairs of initial hash are passed through, and eliminated by Terminator
        # at the end of the chain. If we weren't dealing with the hash, then ignore that.
        result_hash =
          if object.value.is_a?(Hash)
            object.value.merge(result)
          else
            result
          end

        result_hash.keys.each { |k| result_hash.delete(k) if result_hash[k] == Datacaster.absent }
        Datacaster.ValidResult(result_hash, meta: {checked_schema: checked_schema})
      else
        Datacaster.ErrorResult(errors)
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
