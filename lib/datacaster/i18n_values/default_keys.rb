require 'set'

module Datacaster
  module I18nValues
    class DefaultKeys < Base
      attr_reader :keys

      def initialize(keys, args = {})
        @keys = keys.to_set
        @args = args
      end

      def ==(other)
        super && @keys == other.keys
      end

      def resolve
        key = @keys.find(&Config.i18n_exists?) || @keys.first
        Config.i18n_t.(key, **@args)
      end

      def with_args(args)
        self.class.new(@keys, @args.merge(args))
      end

      def inspect
        "#<#{self.class.name}(#{@keys.join(', ')}) #{@args.inspect}>"
      end
    end
  end
end
