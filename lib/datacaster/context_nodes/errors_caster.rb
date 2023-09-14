module Datacaster
  module ContextNodes
    class ErrorsCaster < Datacaster::ContextNode
      def initialize(base, error_caster)
        super(base)
        @caster = error_caster
      end

      private

      def transform_errors(errors)
        result = @caster.with_runtime(@runtime).(errors)
        if result.valid?
          result.value
        else
          raise RuntimeError.new("Error caster tried to cast these errors: #{errors.inspect}, but didn't return ValidResult: #{result.inspect}")
        end
      end
    end
  end
end
