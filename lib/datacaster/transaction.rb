module Datacaster
  module Transaction
    class StepErrorResult < RuntimeError
      attr_accessor :result

      def initialize(result)
        super(result.inspect)
        @result = result
      end
    end

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

      def method_missing(m, *args, **kwargs)
        return super unless args.empty? && kwargs.empty?
        return super unless method_defined?(m)
        method = instance_method(m)
        return super unless method.arity == 1

        # convert immediate class method call to lazy instance method call
        ->(*args, **kwargs) { send(m, *args, **kwargs) }
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
      if respond_to?(:perform)
        @runtime = runtime
        begin
          result = perform(object)
        rescue StepErrorResult => e
          return e.result
        end
        @runtime = nil
        return result
      end

      caster = self.class._caster
      unless caster
        raise RuntimeError, "define #perform (#perform_partial, #perform_choosy) method " \
          "or call .perform(caster) or .perform { caster } beforehand", caller
      end
      caster.
        with_object_context(self).
        with_runtime(runtime).
        (object)
    end

    def step(arg = nil, &block)
      result = Datacaster::Predefined.cast(&block).
        with_object_context(self).
        with_runtime(@runtime).
        (arg)
    end

    def step!(arg = nil, &block)
      result = step(arg, &block)

      if result.valid?
        result.value
      else
        raise StepErrorResult.new(result)
      end
    end
  end
end
