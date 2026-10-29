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

        entry = (@pointer_stack.last[key] ||= {})
        # A key checked unconditionally stays so; checks made inside it are dropped
        @pointer_stack.push(entry == true ? {} : entry)
        @should_check_stack.push(false)
        result = yield if block_given?
        was_checked = @should_check_stack.pop
        @pointer_stack.pop
        @pointer_stack.last[key] = true unless was_checked
        result
      end

      def will_check!
        return if @ignore
        @should_check_stack[-1] = true
      end

      def will_not_check!
        @should_check_stack[-1] = false
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
          Utils.merge_checks!(@pointer_stack[-1], schema)
        end
      end

      # Records the checks made by the block only if its result is valid,
      # as a nested schema reports its checks to the parent only on success
      def record_checks_on_success
        level = @pointer_stack[-1]
        saved_should_check = @should_check_stack[-1]
        @pointer_stack[-1] = {}

        result = yield
        branch = @pointer_stack[-1]
        @pointer_stack[-1] = level

        if result.valid?
          if branch == true
            @pointer_stack[-1] = true unless level == true
          elsif level != true
            Utils.merge_checks!(level, branch)
          end
        else
          @should_check_stack[-1] = saved_should_check
        end
        result
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
