module Datacaster
  module I18nValues
    class Base
      attr_reader :args

      def *(other)
        other = other.first if other.is_a?(Array) && other.length == 1
        result = apply(other)

        result = [result] unless result.is_a?(Array) || result.is_a?(Hash)
        result
      end

      def ==(other)
        self.class == other.class && @args == other.args
      end

      private

      def apply(other)
        if !other.is_a?(Base)
          return apply_to_literal(other)
        end

        merged_args = other.args.merge(@args)

        # DefaultKeys(['.relative', 'full.path']) * DefaultKeys(['.relative', 'full.path']) -> left
        # DefaultKeys(['.relative', 'full.path']) * any -> error
        if is_a?(DefaultKeys)
          return DefaultKeys.new(@keys, merged_args) if other.is_a?(DefaultKeys)
          raise RuntimeError.new("Can not apply #{inspect} to #{other.inspect}")
        end

        # Key(...) * DefaultKeys('full.path') -> left
        # Scope(x) * DefaultKeys(['.relative', 'full_path']) = DefaultKeys(['x.relative', 'full_path'])
        if other.is_a?(DefaultKeys)
          return Key.new(@key, merged_args) if is_a?(Key)

          scoped_keys =
            other.keys.map do |x|
              if x[0] == '.'
                "#{@scope}#{x}"
              else
                x
              end
            end
          return DefaultKeys.new(scoped_keys, merged_args)
        end

        # Key(...) * Key(...) -> error
        # Key(...) * Scope(...) -> error
        if is_a?(Key)
          raise RuntimeError.new("Can not apply #{inspect} to #{other.inspect}")
        end

        # Scope(...) * Key('y') = Key('y')
        # Scope('.x') * Key('.y') = Key('.x.y')
        # Scope('x') * Key('.y') = Key('x.y')
        if other.is_a?(Key)
          return Key.new(other.key, merged_args) if other.key[0] != '.'
          return Key.new("#{@scope}#{other.key}", merged_args)
        end

        # Scope(...) * Scope(...) -> error
        raise RuntimeError.new("Can not apply #{inspect} to #{other.inspect}")
      end

      def apply_to_literal(other)
        # Base * Other -> Other
        return other if !other.is_a?(Hash) && !other.is_a?(Array)

        # Key(...) * Array -> Array
        # DefaultKeys(...) * Array -> Array
        # Key(...) * Hash -> Hash
        # DefaultKeys(...) * Hash -> Hash
        return other unless is_a?(Scope)

        # Scope(...) * Array -> map
        return other.map { |x| self * x } if other.is_a?(Array)

        # Scope(...) * Hash -> map values
        other.transform_values { |x| self * x }
      end
    end
  end
end
