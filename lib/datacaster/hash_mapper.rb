module Datacaster
  class HashMapper < Base
    def initialize(fields)
      @fields = fields
    end

    def call(object)
      object = super(object)

      # return Datacaster.ErrorResult(["must be hash"]) unless object.value.is_a?(Hash)

      checked_schema = object.meta[:checked_schema].dup || {}

      errors = {}
      result = {}

      @fields.each do |key, validator|
        new_value = validator.(object)

        # transform_to_hash([:a, :b, :c] => pick(:a, :b, :c) & ...)
        keys = Array(key)
        values_or_errors =
          if new_value.valid?
            new_value.value.nil? ? [nil] : Array(new_value.value)
          else
            Array(new_value.errors)
          end

        if keys.length != values_or_errors.length
          raise TypeError.new("When using transform_to_hash([:a, :b, :c] => validator), validator should return Array "\
            "with number of elements equal to the number of elements in left-hand-side array.\n" \
            "Got the following (values or errors) instead: #{keys.inspect} => #{values_or_errors.inspect}.")
        end

        if new_value.valid?
          keys.each.with_index do |key, i|
            result[key] = values_or_errors[i]
            checked_schema[key] = true
          end

          single_returned_schema = new_value.meta[:checked_schema].dup
          checked_schema[keys.first] = single_returned_schema if keys.length == 1 && single_returned_schema
        else
          errors.merge!(keys.zip(values_or_errors).to_h)
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
