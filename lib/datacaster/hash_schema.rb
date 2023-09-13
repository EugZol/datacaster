module Datacaster
  class HashSchema < Base
    def initialize(fields)
      @fields = fields
    end

    def cast(object, runtime:)
      return Datacaster.ErrorResult(["must be hash"]) unless object.is_a?(Hash)

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
          errors[key] = new_value.errors
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

    def inspect
      field_descriptions =
        @fields.map do |k, v|
          "#{k.inspect} => #{v.inspect}"
        end

      "#<Datacaster::HashSchema {#{field_descriptions.join(', ')}}>"
    end
  end
end
