module Datacaster
  module AroundNodes
    class Caster < Datacaster::AroundNode
      def cast(object, runtime:)
        super

        Runtimes::Base.(runtime, @run, object, @around.with_runtime(runtime))
      end
    end
  end
end
