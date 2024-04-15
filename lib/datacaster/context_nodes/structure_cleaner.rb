module Datacaster
  module ContextNodes
    class StructureCleaner < Datacaster::ContextNode
      def initialize(base, strategy = :fail)
        super(base)

        unless %i[fail remove pass].include?(strategy)
          raise ArgumentError.new("Strategy should be :fail (return error on extra keys), :remove (remove extra keys) or :pass (ignore presence of extra keys), instead got #{strategy.inspect}")
        end

        @strategy = strategy
      end

      def inspect
        "#<#{self.class.name}(#{@strategy}) base: #{@base.inspect}>"
      end

      private

      def create_runtime(parent)
        Runtimes::StructureCleaner.new(parent)
      end

      def transform_result(result)
        return result unless result.valid?
        result = cast_success(result)

        # Notify parent runtime of current runtime's schema
        unless @runtime.unchecked?
          parent_runtime = @runtime.instance_variable_get(:@parent)
          if parent_runtime.respond_to?(:checked_schema!)
            parent_runtime.checked_schema!(@runtime.checked_schema)
          end
        end

        result
      end

      def cast_success(result)
        return result if @strategy == :pass
        return result if @runtime.unchecked?

        cast_value(result, @runtime.checked_schema)
      end

      def cast_value(result, schema)
        return result if schema == true

        case result.value!
        when Array
          cast_array(result, schema)
        when Hash
          cast_hash(result, schema)
        else
          raise RuntimeError, "Expected hash or array inside result when checking #{result.inspect} " \
            "(schema is #{schema.inspect})", caller
        end
      end

      def cast_array(result, schema)
        value = result.value!

        unchecked_indicies = value.each_index.to_a - schema.keys
        if unchecked_indicies.any?
          return Datacaster.ErrorResult(unchecked_indicies.map { |i| [i, 'must be absent'] }.to_h)
        end

        output =
          value.map.with_index do |x, i|
            cast_value(Datacaster.ValidResult(x), schema[i])
          end

        if output.all?(&:valid?)
          Datacaster.ValidResult(output.map(&:value))
        else
          Datacaster.ErrorResult(output.each.with_index.reject { |x, _| x.valid? }.map { |x, i| [i, x.raw_errors] }.to_h)
        end
      end

      def cast_hash(result, schema)
        errors = {}
        output = {}
        value = result.value!

        value.each do |(k, v)|
          next if v == Datacaster.absent

          unless schema.key?(k)
            errors[k] = ['must be absent'] if @strategy == :fail
            next
          end

          if schema[k] == true
            output[k] = v
            next
          end

          nested_value = cast_value(Datacaster.ValidResult(v), schema[k])
          if nested_value.valid?
            output[k] = nested_value.value
          else
            errors[k] = nested_value.raw_errors
          end
        end

        if errors.empty?
          Datacaster.ValidResult(output)
        else
          Datacaster.ErrorResult(errors)
        end
      end
    end
  end
end
