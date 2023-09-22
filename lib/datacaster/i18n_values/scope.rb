module Datacaster
  module I18nValues
    class Scope < Base
      attr_reader :scope

      def initialize(scope, args = {})
        @scope = scope
        @args = args
      end

      def ==(other)
        super && @scope == other.scope
      end

      def resolve
        raise RuntimeError.new("Tried to resolve i18n scope #{@scope.inspect}. Use #i18n_key or #i18n_default_keys in addition to #i18n_scope.")
      end

      def with_args(args)
        self.class.new(@scope, @args.merge(args))
      end

      def inspect
        "#<#{self.class.name}(#{@scope.inspect}) #{@args.inspect}>"
      end
    end
  end
end
