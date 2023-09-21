require 'ostruct'

module Datacaster
  module Runtimes
    class UserContext < Datacaster::Runtime
      class ContextStruct
        def initialize(parent, user_context)
          super(parent)
          @context_struct = ContextStruct.new(user_context, self)
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

      def context
        @context_struct
      end
    end
  end
end
