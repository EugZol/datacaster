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
        Config.i18n_t.(@scope, **@args)
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
