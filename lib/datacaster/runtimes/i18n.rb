module Datacaster
  module Runtimes
    class I18n < Datacaster::Runtime
      attr_reader :args

      def initialize(*)
        super
        @args = {}
      end

      def i18n_var!(name, value)
        @args[name] = value
      end

      def i18n_vars!(map)
        @args.merge!(map)
      end
    end
  end
end
