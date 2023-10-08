module Datacaster
  module ContextNodes
    class ObjectContext < Datacaster::ContextNode
      def initialize(base, object)
        super(base)
        @object = object
      end

      def inspect
        "#<#{self.class.name}(#{@object.inspect}) base: #{@base.inspect}>"
      end

      private

      def create_runtime(parent)
        Runtimes::ObjectContext.new(parent, @object)
      end
    end
  end
end
