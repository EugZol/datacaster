module Datacaster
  class Base
    def self.merge_errors(left, right)
      add_error_to_base = ->(hash, error) {
        hash[:base] ||= []
        hash[:base] = merge_errors(hash[:base], error)
        hash
      }

      return [] if left.nil? && right.nil?
      return right if left.nil?
      return left if right.nil?

      result = case [left.class, right.class]
      when [Array, Array]
        left | right
      when [Array, Hash]
        add_error_to_base.(right, left)
      when [Hash, Hash]
        (left.keys | right.keys).map do |k|
          [k, merge_errors(left[k], right[k])]
        end.to_h
      when [Hash, Array]
        add_error_to_base.(left, right)
      else
        raise ArgumentError.new("Expected failures to be Arrays or Hashes, left: #{left.inspect}, right: #{right.inspect}")
      end

      result
    end

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
      ThenNode.new(self, other)
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

    def i18n_default_keys(*keys, **args)
      ContextNodes::I18n.new(self, I18nValues::DefaultKeys.new(keys, args))
    end

    def i18n_key(key, **args)
      ContextNodes::I18n.new(self, I18nValues::Key.new(key, args))
    end

    def i18n_map_keys(mapping)
      ContextNodes::I18nKeysMapper.new(self, mapping)
    end

    def i18n_scope(scope, **args)
      ContextNodes::I18n.new(self, I18nValues::Scope.new(scope, args))
    end

    def inspect
      "#<Datacaster::Base>"
    end
  end
end
