module Datacaster
  module I18nValues
    class Key < Base
      attr_reader :keys

      def initialize(keys_or_key, args = {})
        keys = Array(keys_or_key)
        @keys = keys
        @args = args
      end

      def ==(other)
        super && @keys == other.keys
      end

      def resolve
        keys = @keys.select { |x| x[0] != '.' }
        if keys.empty?
          raise RuntimeError.new("No absolute keys among #{@keys.inspect}. Use #i18n_key in addition to #i18n_scope.")
        end
        key = keys.find(&Config.i18n_exists?) || keys.first
        Config.i18n_t.(key, **@args)
      end

      def with_args(args)
        self.class.new(@keys, @args.merge(args))
      end

      def inspect
        "#<#{self.class.name}(#{@keys.inspect}) #{@args.inspect}>"
      end
    end
  end
end
