module Datacaster
  module Runtimes
    class StructureCleaner < Base
      attr_reader :checked_schema

      def initialize(*)
        super
        @checked_schema = {}
        @should_check_stack = [false]
        @pointer_stack = [@checked_schema]
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
