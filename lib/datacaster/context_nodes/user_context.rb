module Datacaster
  module ContextNodes
    class UserContext < Datacaster::ContextNode
      def initialize(base, user_context)
        super(base)
        @user_context = user_context
      end

      def inspect
        "#<#{self.class.name}(#{@user_context.inspect}) base: #{@base.inspect}>"
      end

      private

      def create_runtime(parent)
        Runtimes::UserContext.new(parent, @user_context)
      end
    end
  end
end
