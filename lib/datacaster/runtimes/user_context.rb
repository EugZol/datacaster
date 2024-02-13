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
          if args.length > 1 || block_given?
            return super
          end

          key_present = @context.respond_to?(:key?) && @context.key?(m) ||
            @context.to_h.key?(m.to_sym)

          if key_present && args.empty?
            return @context[m]
          end

          if m =~ /\A.+=\z/ && args.length == 1
            return @context[m[0..-2].to_sym] = args[0]
          end

          begin
            @node.class.send_to_parent(@node, :context).public_send(m, *args)
          rescue NoMethodError
            raise NoMethodError.new("Key #{m.inspect} is not found in the context")
          end
        end
      end

      def initialize(parent, user_context)
        super(parent)
        @context_struct = ContextStruct.new(user_context, self)

        @reserved_instance_variables += instance_variables
      end

      def context
        @context_struct
      end
    end
  end
end
