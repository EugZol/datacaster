module Datacaster
  module Predefined
    extend self

    # Base types

    def cast(&block)
      Caster.new(&block)
    end

    def check(&block)
      Checker.new(&block)
    end

    def compare(value)
      Comparator.new(value)
    end

    def transform(&block)
      Transformer.new(&block)
    end

    def transform_if_present(&block)
      raise 'Expected block' unless block_given?

      Transformer.new(name) { |v| v == Datacaster.absent ? v : block.(v) }
    end

    def try(catched_exception:, &block)
      Trier.new(catched_exception, &block).i18n_default_keys('.try', 'datacaster.errors.try')
    end

    def array_schema(element_caster)
      ArraySchema.new(DefinitionDSL.expand(element_caster))
    end
    alias_method :array_of, :array_schema

    def hash_schema(fields)
      unless fields.is_a?(Hash)
        raise "Expected field definitions in a form of Hash for hash_schema, got #{fields.inspect} instead"
      end
      DefinitionDSL.expand(fields)
    end

    def transform_to_hash(fields)
      HashMapper.new(fields.transform_values { |x| DefinitionDSL.expand(x) })
    end

    def validate(active_model_validations)
      Validator.new(active_model_validations)
    end

    # 'Meta' types

    def absent
      check { |x| x == Datacaster.absent }.i18n_default_keys('.absent', 'datacaster.errors.absent')
    end

    def any
      check { |x| x != Datacaster.absent }.i18n_default_keys('.absent', 'datacaster.errors.any')
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

    def pick(*keys)
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

    def responds_to(method)
      check { |x| x.respond_to?(method) }.i18n_default_keys('.responds_to', 'datacaster.errors.responds_to', reference: method.to_s)
    end

    def must_be(klass)
      check { |x| x.is_a?(klass) }.i18n_default_keys('.must_be', 'datacaster.errors.must_be', reference: klass.name)
    end

    def optional(base)
      absent | base
    end

    # Strict types

    def decimal(digits = 8)
      Trier.new([ArgumentError, TypeError]) do |x|
        # strictly validate format of string, BigDecimal() doesn't do that
        Float(x)

        BigDecimal(x, digits)
      end.i18n_default_keys('.decimal', 'datacaster.errors.decimal')
    end

    def array
      check { |x| x.is_a?(Array) }.i18n_default_keys('.array', 'datacaster.errors.array')
    end

    def float
      check { |x| x.is_a?(Float) }.i18n_default_keys('.float', 'datacaster.errors.float')
    end

    # 'hash' would be a bad method name, because it would override built in Object#hash
    def hash_value
      check { |x| x.is_a?(Hash) }.i18n_default_keys('.hash_value', 'datacaster.errors.hash_value')
    end

    def hash_with_symbolized_keys
      hash_value & transform { |x| x.symbolize_keys }
    end

    def integer
      check { |x| x.is_a?(Integer) }.i18n_default_keys('.integer', 'datacaster.errors.integer')
    end

    def integer32
      integer & check { |x| x.abs <= 2_147_483_647 }.i18n_default_keys('.integer32', 'datacaster.errors.integer32')
    end

    def string
      check { |x| x.is_a?(String) }.i18n_default_keys('.string', 'datacaster.errors.string')
    end

    def non_empty_string
      string & check { |x| !x.empty? }.i18n_default_keys('.non_empty_string', 'datacaster.errors.non_empty_string')
    end

    # Form request types

    def iso8601
      string &
        try(catched_exception: [ArgumentError, TypeError]) { |x| DateTime.iso8601(x) }.
        i18n_default_keys('.iso8601', 'datacaster.errors.iso8601')
    end

    def to_boolean
      cast do |x|
        if ['true', '1', true].include?(x)
          Datacaster.ValidResult(true)
        elsif ['false', '0', false].include?(x)
          Datacaster.ValidResult(false)
        else
          Datacaster.ErrorResult(Datacaster::I18nValues::DefaultKeys.new(['.to_boolean', 'datacaster.errors.to_boolean'], value: x))
        end
      end
    end

    def to_float
      Trier.new([ArgumentError, TypeError]) do |x|
        Float(x)
      end.i18n_default_keys('.to_float', 'datacaster.errors.to_float')
    end

    def to_integer
      Trier.new([ArgumentError, TypeError]) do |x|
        Integer(x)
      end.i18n_default_keys('.to_integer', 'datacaster.errors.to_integer')
    end

    def optional_param(base)
      transform_if_present { |x| x == '' ? Datacaster::Absent.instance : x } & (absent | base)
    end
  end
end
