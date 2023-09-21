module Datacaster
  module ContextNodes
    class I18n < Datacaster::ContextNode
      def initialize(base, i18n_value)
        super(base)
        @i18n_value = i18n_value
      end

      private

      def transform_errors(errors)
        @i18n_value * errors
      end
    end
  end
end
