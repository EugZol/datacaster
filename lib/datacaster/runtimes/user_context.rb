require 'ostruct'

module Datacaster
  module Runtimes
    class UserContext < Base
      class ContextStruct
        def initialize(context, node)
          @context = context
          @node = node
        end

        def method_missing(m, *args)
          if !args.empty? || block_given?
            return super
          end

          if @context.key?(m)
            return @context[m]
          end

          begin
            @node.class.send_to_parent(@node, :context).public_send(m)
          rescue NoMethodError
            raise NoMethodError.new("Key #{m.inspect} is not found in the context")
          end
        end
      end

      def initialize(parent, user_context)
        super(parent)
        @context_struct = ContextStruct.new(user_context, self)
      end

      def context
        @context_struct
      end
    end
  end
end
