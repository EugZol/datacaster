module Datacaster
  module Runtimes
    class StructureCleaner < Base
      attr_accessor :checked_schema

      def initialize(*)
        super
        @ignore = false
        @checked_schema = {}
        @should_check_stack = [false]
        @pointer_stack = [@checked_schema]

        @reserved_instance_variables += instance_variables
      end

      # Array checked schema are the same as hash one, where
      # instead of keys there are array indicies
      def checked_key!(key)
        if @ignore
          return yield if block_given?
          return
        end

        @pointer_stack.last[key] ||= {}
        @pointer_stack.push(@pointer_stack.last[key])
        @should_check_stack.push(false)
        result = yield if block_given?
        was_checked = @should_check_stack.pop
        @pointer_stack.pop
        @pointer_stack.last[key] = true unless was_checked
        result
      end

      def will_check!
        @should_check_stack[-1] = true
      end

      # Notify current runtime that some child runtime has built schema,
      # child runtime's schema is passed as the argument
      def checked_schema!(schema)
        # Current runtime has marked its schema as checked unconditionally
        return if @pointer_stack[-1] == true

        # Child runtime marks its schema as checked unconditionally, so
        # current runtime should do as well
        if schema == true
          @pointer_stack[-1] = true
        # Child runtime's schema should be merged with current runtime's schema
        else
          will_check!
          @pointer_stack[-1].merge!(schema)
        end
      end

      def ignore_checks!(&block)
        @ignore = true
        result = yield
        @ignore = false
        result
      end

      def unchecked?
        @should_check_stack == [false]
      end
    end
  end
end
