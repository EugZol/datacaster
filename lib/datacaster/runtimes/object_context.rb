require 'set'

module Datacaster
  module Runtimes
    class ObjectContext < Base
      def initialize(parent, object)
        super(parent)
        @object = object

        @reserved_instance_variables += instance_variables
      end

      def method_missing(m, *args, &block)
        if @object.respond_to?(m)
          @object.public_send(m, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(m, include_private = false)
        @object.respond_to?(m, include_private) || super
      end

      def after_call!(sender)
        (sender.instance_variables.to_set - sender.reserved_instance_variables).each do |k|
          @object.instance_variable_set(k, sender.instance_variable_get(k))
          sender.remove_instance_variable(k)
        end
        super
      end

      def before_call!(sender)
        super
        (@object.instance_variables.to_set - sender.reserved_instance_variables).each do |k|
          sender.instance_variable_set(k, @object.instance_variable_get(k))
        end
      end
    end
  end
end
