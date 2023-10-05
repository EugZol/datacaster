module Datacaster
  module Transaction
    module ClassMethods
      def perform(caster)
        @_caster = ContextNodes::StructureCleaner.new(caster, :fail)
      end

      def perform_partial(caster)
        @_caster = ContextNodes::StructureCleaner.new(caster, :pass)
      end

      def perform_choosy(caster)
        @_caster = ContextNodes::StructureCleaner.new(caster, :remove)
      end

      def call(*args, **kwargs)
        new.call(*args, **kwargs)
      end
    end

    def self.included(base)
      base.extend Datacaster::Predefined
      base.extend ClassMethods
      base.include Datacaster::Mixin
    end

    def cast(object, runtime:)
      self.class.instance_variable_get(:@_caster).
        with_runtime(runtime).
        (object)
    end
  end
end
