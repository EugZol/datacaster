module Datacaster
  module Transaction
    module ClassMethods
      def _caster
        if @_block
          @_caster = ContextNodes::StructureCleaner.new(@_block.(), @_strategy)
          @_block = nil
          @_strategy = nil
        end
        @_caster
      end

      def _perform(caster, strategy, &block)
        if [caster, block].count(nil) != 1
          raise RuntimeError, "provide either a caster as single argument, or just a block to `perform(...)` or `perform_*(...)` call", caller
        end

        if block
          @_block = block
          @_strategy = strategy
          @_caster = nil
        else
          @_block = nil
          @_strategy = nil
          @_caster = ContextNodes::StructureCleaner.new(caster, strategy)
        end
      end

      def perform(caster = nil, &block)
        _perform(caster, :fail, &block)
      end

      def perform_partial(caster = nil, &block)
        _perform(caster, :pass, &block)
      end

      def perform_choosy(caster = nil, &block)
        _perform(caster, :remove, &block)
      end

      def define_steps(&block)
        instance_eval(&block)
      end

      def call(*args, **kwargs)
        new.call(*args, **kwargs)
      end

      def caster(m)
        cast { |*args, **kwargs| send(m, *args, **kwargs) }
      end

      def checker(m)
        check { |*args, **kwargs| send(m, *args, **kwargs) }
      end

      def comparator(m)
        compare { |*args, **kwargs| send(m, *args, **kwargs) }
      end

      def transformer(m)
        transform { |*args, **kwargs| send(m, *args, **kwargs) }
      end
    end

    def self.included(base)
      base.extend Datacaster::Predefined
      base.extend ClassMethods
      base.include Datacaster::Mixin
    end

    def cast(object, runtime:)
      self.class._caster.
        with_object_context(self).
        with_runtime(runtime).
        (object)
    end
  end
end
