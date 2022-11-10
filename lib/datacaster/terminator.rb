require 'singleton'
require 'dry-monads'

module Datacaster
  class Terminator
    module TerminatorBase
      include Dry::Monads[:result]

      def self.included(klass)
        klass.include Singleton
      end

      def call(object, checked_schema = nil)
        object = super(object)
        checked_schema ||= object.meta[:checked_schema]

        case object.value
        when Array
          check_array(object.value, checked_schema)
        when Hash
          check_hash(object.value, checked_schema)
        else
          Datacaster.ValidResult(object.value)
        end
      end

      def inspect
        "#<Datacaster::Terminator>"
      end

      private

      def check_array(array, checked_schema)
        return Datacaster.ValidResult(array) unless checked_schema

        result = array.zip(checked_schema).map { |x, schema| call(x, schema) }

        if result.all?(&:valid?)
          Datacaster.ValidResult(result.map(&:value))
        else
          Datacaster.ErrorResult(result.each.with_index.reject { |x, _| x.valid? }.map { |x, i| [i, x.errors] }.to_h)
        end
      end

      def check_hash(hash, checked_schema)
        return Datacaster.ValidResult(hash) unless checked_schema

        errors = {}
        result = {}

        hash.each do |(k, v)|
          if v == Datacaster.absent
            next
          end

          unless checked_schema.key?(k)
            errors[k] = ["must be absent"] if is_a?(Raising)
            next
          end

          if checked_schema[k] == true
            result[k] = v
            next
          end

          nested_value = call(v, checked_schema[k])
          if nested_value.valid?
            result[k] = nested_value.value
          else
            errors[k] = nested_value.errors
          end
        end

        if errors.empty?
          Datacaster.ValidResult(result)
        else
          Datacaster.ErrorResult(errors)
        end
      end
    end

    class Raising < Base
      include TerminatorBase
  
      def inspect
        "#<Datacaster::Terminator::Raising>"
      end
    end

    class Sweeping < Base
      include TerminatorBase
  
      def inspect
        "#<Datacaster::Terminator::Sweeping>"
      end
    end
  end
end
