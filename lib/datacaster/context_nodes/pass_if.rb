module Datacaster
  module ContextNodes
    class PassIf < Datacaster::ContextNode
      def cast(object, runtime:)
        @runtime = create_runtime(runtime)
        result = @base.with_runtime(@runtime).call(object)
        result.valid? ? Datacaster::ValidResult(object) : result
      end
    end
  end
end
