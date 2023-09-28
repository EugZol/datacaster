module Datacaster
  class MessageKeysMerger < Base
    def initialize(keys)
      @keys = keys
    end

    def cast(object, runtime:)
      return Datacaster.ErrorResult(I18nValues::Key.new(['.hash_value', 'datacaster.errors.hash_value'], value: object)) unless object.is_a?(Hash)

      result = set_initial_value(object)

      @keys.each do |k|
        result =
          if need_hash_merger?(object)
            merge_hash(result, object[k])
          else
            merge_array_or_scalar(result, object[k])
          end
      end

      result = clean(result)

      Datacaster.ValidResult(
        result.nil? ? Datacaster.absent : result
      )
    end

    private

    def set_initial_value(object)
      need_hash_merger?(object) ? {} : []
    end

    def need_hash_merger?(object)
      @need_hash_merger =
        @need_hash_merger.nil? ? @keys.any? { |k| object[k].is_a?(Hash) } : @need_hash_merger
    end

    def merge_array_or_scalar(unit, merge_with)
      merge_with = [merge_with] unless merge_with.is_a?(Array)
      unit = [unit] unless unit.is_a?(Array)

      result = clean(unit | merge_with)
      result == [] ? Datacaster.absent : result
    end

    def value_or(value, default)
      value.nil? ? default : value
    end

    def merge_hash_with_hash(result, merge_with)
      if merge_with.is_a?(Hash)
        merge_with.each do |k, v|
          result = value_or(result, {})
          result[k] = merge_hash_with_hash(result[k], v)
        end

        result
      else
        result = merge_array_or_scalar(value_or(result, []), merge_with)
      end
    end

    def merge_hash(result, merge_with)
      if merge_with.is_a?(Hash)
        merge_with.each do |k, v|
          result[k] = merge_hash_with_hash(result[k], v)
        end
      else
        result[:base] = merge_array_or_scalar(value_or(result[:base], []), merge_with)
      end

      result
    end

    def clean(value)
      case value
      when Array
        value.delete_if do |v|
          clean(v) if v.is_a?(Hash) || v.is_a?(Array)
          v == Datacaster.absent || v == nil
        end
      when Hash
        value.delete_if do |_k, v|
          clean(v) if v.is_a?(Hash) || v.is_a?(Array)
          v == Datacaster.absent || v == nil
        end
      end
    end
  end
end
