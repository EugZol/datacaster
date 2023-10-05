module Datacaster
  module Predefined
    extend self

    # Base types

    def cast(&block)
      Caster.new(&block)
    end

    def check(error_key = nil, &block)
      Checker.new(error_key, &block)
    end

    def compare(value, error_key = nil)
      Comparator.new(value, error_key)
    end

    def transform(&block)
      Transformer.new(&block)
    end

    def transform_if_present(&block)
      raise 'Expected block' unless block_given?

      Transformer.new { |v| v == Datacaster.absent ? v : block.(v) }
    end

    def try(error_key = nil, catched_exception:, &block)
      Trier.new(catched_exception, error_key, &block)
    end

    def array_schema(element_caster, error_keys = {})
      ArraySchema.new(DefinitionDSL.expand(element_caster), error_keys)
    end
    alias_method :array_of, :array_schema

    def hash_schema(fields, error_key = nil)
      unless fields.is_a?(Hash)
        raise "Expected field definitions in a form of Hash for hash_schema, got #{fields.inspect} instead"
      end
      HashSchema.new(
        fields.transform_values { |f| DefinitionDSL.expand(f) },
        error_key
      )
    end

    def transform_to_hash(fields)
      HashMapper.new(fields.transform_values { |x| DefinitionDSL.expand(x) })
    end

    def validate(active_model_validations)
      Validator.new(active_model_validations)
    end

    def schema(base)
      ContextNodes::StructureCleaner.new(base, strategy: :fail)
    end

    def choosy_schema(base)
      ContextNodes::StructureCleaner.new(base, strategy: :remove)
    end

    def partial_schema(base)
      ContextNodes::StructureCleaner.new(base, strategy: :pass)
    end

    # 'Meta' types

    def absent(error_key = nil, on: nil)
      error_keys = ['.absent', 'datacaster.errors.absent']
      error_keys.unshift(error_key) if error_key

      cast do |x|
        if x == Datacaster.absent ||
          (!on.nil? && x.respond_to?(on) && x.public_send(on))
          Datacaster.ValidResult(Datacaster.absent)
        else
          Datacaster.ErrorResult(
            I18nValues::Key.new(error_keys, value: x)
          )
        end
      end
    end

    def any(error_key = nil)
      error_keys = ['.any', 'datacaster.errors.any']
      error_keys.unshift(error_key) if error_key
      check { |x| x != Datacaster.absent }.i18n_key(*error_keys)
    end

    def default(value, on: nil)
      transform do |x|
        if x == Datacaster.absent ||
          (!on.nil? && x.respond_to?(on) && x.public_send(on))
          value
        else
          x
        end
      end
    end

    def transform_to_value(value)
      transform { value }
    end

    def remove
      transform { Datacaster.absent }
    end

    def pass
      transform(&:itself)
    end

    def switch(*base, **on_clauses)
      switch =
        if base.length == 0
          SwitchNode.new
        else
          SwitchNode.new(base)
        end
      on_clauses.reduce(switch) do |result, (k, v)|
        result.on(k, v)
      end
    end

    def pass_if(base)
      ContextNodes::PassIf.new(base)
    end

    def pick(*keys, strict: false)
      raise RuntimeError.new("provide keys to pick, e.g. pick(:key)") if keys.empty?

      must_be(Enumerable) & transform { |value|
        result =
          keys.map do |key|
            if value.respond_to?(:key?) && !value.key?(key)
              Datacaster.absent
            elsif value.respond_to?(:length) && key.is_a?(Integer) && key > 0 && key >= value.length
              Datacaster.absent
            else
              value[key]
            end
          end

        keys.length == 1 ? result.first : result
      }
    end

    def merge_message_keys(*keys)
      MessageKeysMerger.new(keys)
    end

    def responds_to(method, error_key = nil)
      error_keys = ['.responds_to', 'datacaster.errors.responds_to']
      error_keys.unshift(error_key) if error_key
      check { |x| x.respond_to?(method) }.i18n_key(*error_keys, reference: method.to_s)
    end

    def must_be(klass, error_key = nil)
      error_keys = ['.must_be', 'datacaster.errors.must_be']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(klass) }.i18n_key(*error_keys, reference: klass.name)
    end

    def optional(base, on: nil)
      return absent | base if on == nil
      cast do |x|
        if x == Datacaster.absent ||
          (!on.nil? && x.respond_to?(on) && x.public_send(on))
          Datacaster.ValidResult(Datacaster.absent)
        else
          base.(x)
        end
      end
    end

    # Strict types

    def decimal(digits = 8, error_key = nil)
      error_keys = ['.decimal', 'datacaster.errors.decimal']
      error_keys.unshift(error_key) if error_key

      Trier.new([ArgumentError, TypeError]) do |x|
        # strictly validate format of string, BigDecimal() doesn't do that
        Float(x)

        BigDecimal(x, digits)
      end.i18n_key(*error_keys)
    end

    def array(error_key = nil)
      error_keys = ['.array', 'datacaster.errors.array']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(Array) }.i18n_key(*error_keys)
    end

    def float(error_key = nil)
      error_keys = ['.float', 'datacaster.errors.float']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(Float) }.i18n_key(*error_keys)
    end

    # 'hash' would be a bad method name, because it would override built in Object#hash
    def hash_value(error_key = nil)
      error_keys = ['.hash_value', 'datacaster.errors.hash_value']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(Hash) }.i18n_key(*error_keys)
    end

    def hash_with_symbolized_keys(error_key = nil)
      hash_value(error_key) & transform { |x| x.symbolize_keys }
    end

    def included_in(*values, error_key: nil)
      error_keys = ['.included_in', 'datacaster.errors.included_in']
      error_keys.unshift(error_key) if error_key
      check { |x| values.include?(x) }.i18n_key(*error_keys, reference: values.map(&:to_s).join(', '))
    end

    def integer(error_key = nil)
      error_keys = ['.integer', 'datacaster.errors.integer']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(Integer) }.i18n_key(*error_keys)
    end

    def integer32(error_key = nil)
      error_keys = ['.integer32', 'datacaster.errors.integer32']
      error_keys.unshift(error_key) if error_key
      integer(error_key) & check { |x| x.abs <= 2_147_483_647 }.i18n_key(*error_keys)
    end

    def string(error_key = nil)
      error_keys = ['.string', 'datacaster.errors.string']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(String) }.i18n_key(*error_keys)
    end

    def non_empty_string(error_key = nil)
      error_keys = ['.non_empty_string', 'datacaster.errors.non_empty_string']
      error_keys.unshift(error_key) if error_key
      string(error_key) & check { |x| !x.empty? }.i18n_key(*error_keys)
    end

    # Form request types

    def iso8601(error_key = nil)
      error_keys = ['.iso8601', 'datacaster.errors.iso8601']
      error_keys.unshift(error_key) if error_key

      string(error_key) &
        try(catched_exception: [ArgumentError, TypeError]) { |x| DateTime.iso8601(x) }.
          i18n_key(*error_keys)
    end

    def to_boolean(error_key = nil)
      error_keys = ['.to_boolean', 'datacaster.errors.to_boolean']
      error_keys.unshift(error_key) if error_key

      cast do |x|
        if ['true', '1', true].include?(x)
          Datacaster.ValidResult(true)
        elsif ['false', '0', false].include?(x)
          Datacaster.ValidResult(false)
        else
          Datacaster.ErrorResult(I18nValues::Key.new(error_keys, value: x))
        end
      end
    end

    def to_float(error_key = nil)
      error_keys = ['.to_float', 'datacaster.errors.to_float']
      error_keys.unshift(error_key) if error_key

      Trier.new([ArgumentError, TypeError]) do |x|
        Float(x)
      end.i18n_key(*error_keys)
    end

    def to_integer(error_key = nil)
      error_keys = ['.to_integer', 'datacaster.errors.to_integer']
      error_keys.unshift(error_key) if error_key

      Trier.new([ArgumentError, TypeError]) do |x|
        Integer(x)
      end.i18n_key(*error_keys)
    end

    def optional_param(base)
      transform_if_present { |x| x == '' ? Datacaster::Absent.instance : x } & (absent | base)
    end
  end
end
