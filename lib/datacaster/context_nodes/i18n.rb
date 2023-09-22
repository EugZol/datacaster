module Datacaster
  module ContextNodes
    class I18n < Datacaster::ContextNode
      def initialize(base, i18n_value)
        super(base)
        @i18n_value = i18n_value
      end

      private

      def create_runtime(parent)
        Runtimes::I18n.new(parent)
      end

      def transform_errors(errors)
        @i18n_value.with_args(runtime.args) * errors
      end
    end
  end
end
