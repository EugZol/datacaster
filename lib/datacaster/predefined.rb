module Datacaster
  module Predefined
    extend self

    # Base types

    def cast(name = 'Anonymous', &block)
      Caster.new(name, &block)
    end

    def check(name = 'Anonymous', error = 'is invalid', &block)
      Checker.new(name, error, &block)
    end

    def compare(value, name = 'Anonymous', error = nil)
      Comparator.new(value, name, error)
    end

    def transform(name = 'Anonymous', &block)
      Transformer.new(name, &block)
    end

    def transform_if_present(name = 'Anonymous', &block)
      raise 'Expected block' unless block_given?

      Transformer.new(name) { |v| v == Datacaster.absent ? v : block.(v) }
    end

    def try(name = 'Anonymous', error = 'is invalid', catched_exception:, &block)
      Trier.new(name, error, catched_exception, &block)
    end

    def array_schema(element_caster)
      ArraySchema.new(element_caster)
    end

    def hash_schema(fields)
      HashSchema.new(fields)
    end

    def transform_to_hash(fields)
      HashMapper.new(fields)
    end

    def validate(active_model_validations, name = 'Anonymous')
      Validator.new(active_model_validations, name)
    end

    # 'Meta' types

    def absent
      check('Absent', 'must be absent') { |x| x == Datacaster.absent }
    end

    def any
      check('Any', 'must be set') { |x| x != Datacaster.absent }
    end

    def transform_to_value(value)
      transform('ToValue') { value }
    end

    def remove
      transform('Remove') { Datacaster.absent }
    end

    def pass
      transform('Pass', &:itself)
    end

    def pick(*keys)
      must_be(Enumerable) & transform("Picker") { |value|
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
      check('RespondsTo', "must respond to #{method.inspect}") { |x| x.respond_to?(method) }
    end

    def must_be(klass)
      check('MustBe', "must be #{klass.inspect}") { |x| x.is_a?(klass) }
    end

    def optional(base)
      absent | base
    end

    # Strict types

    def decimal(digits = 8)
      Trier.new('Decimal', 'must be decimal', [ArgumentError, TypeError]) do |x|
        # strictly validate format of string, BigDecimal() doesn't do that
        Float(x)

        BigDecimal(x, digits)
      end
    end

    def array
      check('Array', 'must be array') { |x| x.is_a?(Array) }
    end

    def float
      check('Float', 'must be float') {  |x| x.is_a?(Float) }
    end

    # 'hash' is a bad method name, because it will overwrite built in Object#hash
    def hash_value
      check('Hash', 'must be hash') { |x| x.is_a?(Hash) }
    end

    def hash_with_symbolized_keys
      hash_value & transform("SymbolizeKeys") { |x| x.symbolize_keys }
    end

    def integer
      check('Integer', 'must be integer') { |x| x.is_a?(Integer) }
    end

    def integer32
      integer & check('FourBytes', 'out of range') { |x| x.abs <= 2_147_483_647 }
    end

    def string
      check('String', 'must be string') { |x| x.is_a?(String) }
    end

    def non_empty_string
      string & check('NonEmptyString', 'must be present') { |x| !x.empty? }
    end

    # Form request types

    def iso8601
      string &
        try('ISO8601', 'must be iso8601 string', catched_exception: [ArgumentError, TypeError]) { |x| DateTime.iso8601(x) }
    end

    def to_boolean
      cast('ToBoolean') do |x|
        if ['true', '1', true].include?(x)
          Datacaster.ValidResult(true)
        elsif ['false', '0', false].include?(x)
          Datacaster.ValidResult(false)
        else
          Datacaster.ErrorResult(['must be boolean'])
        end
      end
    end

    def to_float
      Trier.new('ToFloat', 'must be float', [ArgumentError, TypeError]) do |x|
        Float(x)
      end
    end

    def to_integer
      Trier.new('ToInteger', 'must be integer', [ArgumentError, TypeError]) do |x|
        Integer(x)
      end
    end

    def optional_param(base)
      transform_if_present("optional_param(#{base.inspect})") { |x| x == '' ? Datacaster::Absent.instance : x } & (absent | base)
    end
  end
end
