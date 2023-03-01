module Datacaster
  class HashSchema < Base
    def initialize(fields)
      @fields = fields
      # support of shortcut nested validation definitions, e.g. array_schema(a: [integer], b: {c: integer})
      @fields.transform_values! { |validator| shortcut_definition(validator) }
    end

    def cast(object)
      object = super(object)
      return Datacaster.ErrorResult(["must be hash"]) unless object.value.is_a?(Hash)

      checked_schema = object.meta[:checked_schema].dup || {}

      errors = {}
      result = {}

      @fields.each do |key, validator|
        value =
          if object.value.key?(key)
            object.value[key]
          else
            Datacaster.absent
          end

        new_value = validator.(value)
        if new_value.valid?
          result[key] = new_value.value
          checked_schema[key] = new_value.meta[:checked_schema].dup || true
        else
          errors[key] = new_value.errors
        end
      end

      if errors.empty?
        # All unchecked key-value pairs are passed through, and eliminated by Terminator
        # at the end of the chain
        result_hash = object.value.merge(result)
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

      "#<Datacaster::HashSchema {#{field_descriptions.join(', ')}}>"
    end
  end
end
