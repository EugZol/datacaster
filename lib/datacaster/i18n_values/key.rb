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
