require 'set'

module Datacaster
  module Runtimes
    class Base
      attr_reader :reserved_instance_variables

      def self.call(r, proc, *args)
        r.before_call!(r)
        result = r.instance_exec(*args, &proc)
        r.after_call!(r)
        result
      end

      def self.send_to_parent(r, m, *args, &block)
        parent = r.instance_variable_get(:@parent)
        not_found!(m) if parent.nil?
        call(parent, -> { public_send(m, *args, &block) })
      end

      def self.not_found!(m)
        raise NoMethodError.new("Method #{m.inspect} is not available in current runtime context")
      end

      def initialize(parent = nil)
        @parent = parent

        # We won't be setting any instance variables outside this
        # constructor, so we can proxy all the rest to the @object
        @reserved_instance_variables = Set.new(instance_variables + [:@reserved_instance_variables])
      end

      def method_missing(m, *args, &block)
        self.class.send_to_parent(self, m, *args, &block)
      end

      def respond_to_missing?(m, include_private = false)
        !@parent.nil? && @parent.respond_to?(m, include_private)
      end

      def after_call!(sender)
        @parent.after_call!(sender) if @parent
      end

      def before_call!(sender)
        @parent.before_call!(sender) if @parent
      end

      def inspect
        "#<#{self.class.name} parent: #{@parent.inspect}>"
      end

      def to_s
        inspect
      end

      def Success(v)
        Datacaster.ValidResult(v)
      end

      def Failure(v)
        Datacaster.ErrorResult(v)
      end
    end
  end
end
