module Datacaster
  module I18nValues
    class Base
      attr_reader :args

      def *(other, additional_scope = [])
        # To allow redefine array/hash errors with #i18n_key
        other = other.first if other.is_a?(Array) && other.length == 1
        result = apply(other, additional_scope)

        result = [result] unless result.is_a?(Array) || result.is_a?(Hash)
        result
      end

      def ==(other)
        self.class == other.class && @args == other.args
      end

      private

      def apply(other, additional_scope = [])
        if !other.is_a?(Base)
          return apply_to_literal(other, additional_scope)
        end

        # Key(...) * Scope(...) -> error
        if is_a?(Key) && !other.is_a?(Key)
          raise RuntimeError.new("Can not apply #{inspect} to #{other.inspect}")
        end

        merged_args = other.args.merge(@args)

        # Key(...) * Key(...) -> left
        if is_a?(Key) && other.is_a?(Key)
          return Key.new(@keys, merged_args)
        end

        # Scope('x') * Key(['.relative', 'full_path']) = Key(['x.relative', 'full_path'])
        if is_a?(Scope) && other.is_a?(Key)
          scoped_keys =
            other.keys.flat_map do |x|
              next x if x[0] != '.'

              keys = ["#{@scope}#{x}"]
              next keys if x.count('.') > 1

              accumulator = ""
              additional_scope.each do |k|
                accumulator << ".#{k}"
                keys.unshift "#{@scope}#{accumulator}#{x}"
              end

              keys
            end
          return Key.new(scoped_keys, merged_args)
        end

        # Scope(...) * Scope(...) -> error
        raise RuntimeError.new("Can not apply #{inspect} to #{other.inspect}")
      end

      def apply_to_literal(other, additional_scope = [])
        # Base * Other -> Other
        return other if !other.is_a?(Hash) && !other.is_a?(Array)

        # Key(...) * Array -> Array
        # Key(...) * Hash -> Hash
        return other if is_a?(Key)

        # Scope(...) * Array -> map
        return other.map { |x| self.*(x, additional_scope) } if other.is_a?(Array)

        # Scope(...) * Hash -> map values
        other.map do |(k, v)|
          new_value =
            case k
            when String, Symbol
              self.*(v, [*additional_scope, k])
            else
              self.*(v, [*additional_scope])
            end
          [k, new_value]
        end.to_h
      end
    end
  end
end
