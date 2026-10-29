module Datacaster
  module ContextNodes
    class PassIf < Datacaster::ContextNode
      def cast(object, runtime:)
        result = @base.with_runtime(create_runtime(runtime)).call(object)
        result.valid? ? Datacaster::ValidResult(object) : result
      end
    end
  end
end
