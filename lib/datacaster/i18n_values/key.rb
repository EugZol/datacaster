module Datacaster
  module I18nValues
    class Key < Base
      attr_reader :key

      def initialize(key, args = {})
        @key = key
        @args = args
      end

      def ==(other)
        super && @key == other.key
      end

      def resolve
        if @key[0] == '.'
          raise RuntimeError.new("Tried to resolve non-absolute key #{@key.inspect}. Use keys which don't start from the dot ('.') in one of related #i18n_key, #i18n_default_keys or #i18n_scope.")
        end
        Config.i18n_t.(@key, **@args)
      end

      def with_args(args)
        self.class.new(@key, @args.merge(args))
      end

      def inspect
        "#<#{self.class.name}(#{@key.inspect}) #{@args.inspect}>"
      end
    end
  end
end
