module Datacaster
  module Mixin
    def &(other)
      AndNode.new(self, other)
    end

    def |(other)
      OrNode.new(self, other)
    end

    def *(other)
      AndWithErrorAggregationNode.new(self, other)
    end

    def cast_errors(error_caster)
      ContextNodes::ErrorsCaster.new(self, error_caster)
    end

    def then(other)
      ThenNode.new(self, DefinitionDSL.expand(other))
    end

    def with_context(context)
      unless context.is_a?(Hash)
        raise "with_context expected Hash as argument, got #{context.inspect} instead"
      end
      ContextNodes::UserContext.new(self, context)
    end

    def call(object)
      call_with_runtime(object, Runtimes::Base.new)
    end

    def call_with_runtime(object, runtime)
      result = cast(object, runtime: runtime)
      unless result.is_a?(Result)
        raise RuntimeError.new("Caster should've returned Datacaster::Result, but returned #{result.inspect} instead")
      end
      result
    end

    def with_runtime(runtime)
      ->(object) do
        call_with_runtime(object, runtime)
      end
    end

    def i18n_key(*keys, **args)
      ContextNodes::I18n.new(self, I18nValues::Key.new(keys, args))
    end

    def i18n_map_keys(mapping)
      ContextNodes::I18nKeysMapper.new(self, mapping)
    end

    def i18n_scope(scope, **args)
      ContextNodes::I18n.new(self, I18nValues::Scope.new(scope, args))
    end

    def i18n_vars(vars)
      ContextNodes::I18n.new(self, I18nValues::Scope.new(nil, vars))
    end

    def inspect
      "#<Datacaster::Base>"
    end
  end
end
