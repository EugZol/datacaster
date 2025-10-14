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
      comparator = Comparator.new(value, error_key)

      if value.nil?
        comparator.json_schema(type: 'null')
      else
        comparator.json_schema(enum: [value])
      end
    end

    def run(&block)
      Runner.new(&block)
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

    def array_schema(element_caster, error_keys = {}, allow_empty: true)
      ArraySchema.new(DefinitionDSL.expand(element_caster), error_keys, allow_empty:)
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

    def strict_hash_schema(fields, error_key = nil)
      schema(hash_schema(fields, error_key))
    end

    def choosy_hash_schema(fields, error_key = nil)
      choosy_schema(hash_schema(fields, error_key))
    end

    def transform_to_hash(fields)
      HashMapper.new(fields.transform_values { |x| DefinitionDSL.expand(x) })
    end

    def validate(active_model_validations)
      Validator.new(active_model_validations)
    end

    def schema(base)
      ContextNodes::StructureCleaner.new(base, :fail)
    end

    def choosy_schema(base)
      ContextNodes::StructureCleaner.new(base, :remove)
    end

    def partial_schema(base)
      ContextNodes::StructureCleaner.new(base, :pass)
    end

    # 'Around' types

    def cast_around(&block)
      AroundNodes::Caster.new(&block)
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
      end.json_schema_attributes(required: false)
    end

    def any(error_key = nil)
      error_keys = ['.any', 'datacaster.errors.any']
      error_keys.unshift(error_key) if error_key
      check { |x| x != Datacaster.absent }.i18n_key(*error_keys)
    end

    def attribute(*keys)
      if keys.empty? || keys.any? { |k| !Datacaster::Utils.pickable?(k) }
        raise RuntimeError, "each argument should be String, Symbol, Integer or an array thereof", caller
      end

      transform do |input|
        result =
          keys.map do |key|
            Array(key).reduce(input) do |result, k|
              if result.respond_to?(k)
                result.public_send(k)
              else
                break Datacaster.absent
              end
            end
          end
        keys.length == 1 ? result.first : result
      end
    end

    def default(value, on: nil)
      transform do |x|
        if x == Datacaster.absent ||
          (!on.nil? && x.respond_to?(on) && x.public_send(on))
          Datacaster::Utils.deep_freeze(value)
        else
          x
        end
      end.json_schema_attributes(required: false)
    end

    def merge_message_keys(*keys)
      MessageKeysMerger.new(keys)
    end

    def must_be(klass, error_key = nil)
      error_keys = ['.must_be', 'datacaster.errors.must_be']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(klass) }.i18n_key(*error_keys, reference: klass.name)
    end

    def optional(base, on: nil)
      if on == nil
        return (absent | base).json_schema { base.to_json_schema }.json_schema_attributes(required: false)
      end

      caster = cast do |x|
        if x == Datacaster.absent ||
          (!on.nil? && x.respond_to?(on) && x.public_send(on))
          Datacaster.ValidResult(Datacaster.absent)
        else
          base.(x)
        end
      end

      caster
        .json_schema(base.to_json_schema)
        .json_schema_attributes(required: false)
    end

    def pass
      cast { |v| Datacaster::ValidResult(v) }
        .json_schema_attributes(required: false)
    end

    def pass_if(base)
      ContextNodes::PassIf.new(base)
    end

    def pick(*keys)
      if keys.empty?
        raise RuntimeError, "pick(key, ...) accepts at least one argument", caller
      end

      if wrong = keys.find { |k| !Datacaster::Utils.pickable?(k) }
        raise RuntimeError, "each argument should be String, Symbol, Integer or an array thereof, instead got #{wrong.inspect}", caller
      end

      retrieve_key = -> (from, key) do
        if from.respond_to?(:key?) && !from.key?(key)
          Datacaster.absent
        elsif from.respond_to?(:length) && key.is_a?(Integer) && key > 0 && key >= from.length
          Datacaster.absent
        elsif !from.respond_to?(:[])
          Datacaster.absent
        else
          from[key]
        end
      end

      json_schema = -> (previous) do
        previous = previous.apply({
          'type' => 'object',
          'properties' => keys.map { |k, v| [k.to_s, JsonSchemaResult.new] }.to_h
        })

        if keys.length == 1
          previous.with_focus_key(keys[0].to_s)
        else
          previous.with_focus_key(false)
        end
      end

      must_be(Enumerable) & cast { |input|
        result =
          keys.map do |key|
            Array(key).reduce(input) do |result, k|
              result = retrieve_key.(result, k)
              break result if result == Datacaster.absent
              result
            end
          end
        result = keys.length == 1 ? result.first : result
        Datacaster::ValidResult(result)
      }.json_schema(&json_schema).json_schema_attributes(picked: keys)
    end

    def relate(left, op, right, error_key: nil)
      error_keys = ['.relate', 'datacaster.errors.relate']
      additional_vars = {}

      left_caster = left
      if Datacaster::Utils.pickable?(left)
        left_caster = pick(left)
      elsif !Datacaster.instance?(left)
        raise RuntimeError, "provide String, Symbol, Integer or array thereof instead of #{left.inspect}", caller
      end

      right_caster = right
      if Datacaster::Utils.pickable?(right)
        right_caster = pick(right)
      elsif !Datacaster.instance?(right)
        raise RuntimeError, "provide String, Symbol, Integer or array thereof instead of #{right.inspect}", caller
      end

      op_caster = op
      if op.is_a?(String) || op.is_a?(Symbol)
        op_caster = check { |(l, r)| l.respond_to?(op) && l.public_send(op, r) }
      elsif !Datacaster.instance?(left)
        raise RuntimeError, "provide String or Symbol instead of #{op.inspect}", caller
      end

      {left: left, op: op, right: right}.each do |k, v|
        if [String, Symbol, Integer].any? { |c| v.is_a?(c) }
          additional_vars[k] = v
        end
      end

      if additional_vars.length == 3
        error_keys.unshift(".#{left}.#{op}.#{right}")
      end
      error_keys.unshift(error_key) if error_key

      cast do |value|
        left_result = left_caster.(value)
        next left_result unless left_result.valid?
        i18n_var!(:left, left_result.value) unless additional_vars.key?(:left)

        right_result = right_caster.(value)
        next right_result unless right_result.valid?
        i18n_var!(:right, right_result.value) unless additional_vars.key?(:right)

        result = op_caster.([left_result.value, right_result.value])
        next Datacaster.ErrorResult([I18nValues::Key.new(error_keys)]) unless result.valid?

        Datacaster.ValidResult(value)
      end.i18n_vars(additional_vars)
    end

    def remove
      transform { Datacaster.absent }
    end

    def responds_to(method, error_key = nil)
      error_keys = ['.responds_to', 'datacaster.errors.responds_to']
      error_keys.unshift(error_key) if error_key
      check { |x| x.respond_to?(method) }.i18n_key(*error_keys, reference: method.to_s)
    end

    def steps(*casters)
      AndNode.new(*casters)
    end

    def switch(base = nil, **on_clauses)
      switch = SwitchNode.new(base)
      on_clauses.reduce(switch) do |result, (k, v)|
        result.on(k, v)
      end
    end

    def transform_to_value(value)
      value = Datacaster::Utils.deep_freeze(value)
      transform { value }
    end

    def with(keys, caster)
      keys = Array(keys)

      unless Datacaster::Utils.pickable?(keys)
        raise RuntimeError, "provide String, Symbol, Integer or an array thereof instead of #{keys.inspect}", caller
      end

      if keys.length == 1
        return transform_to_hash(keys[0] => pick(keys[0]) & caster)
      end

      with(keys[0], must_be(Enumerable) & with(keys[1..-1], caster))
    end

    # Strict types

    def numeric(error_key = nil)
      error_keys = ['.numeric', 'datacaster.errors.numeric']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(Numeric) }.
        i18n_key(*error_keys).
        json_schema(oneOf: [{ 'type' => 'string' }, { 'type' => 'number' }])
    end

    def decimal(digits = 8, error_key = nil)
      error_keys = ['.decimal', 'datacaster.errors.decimal']
      error_keys.unshift(error_key) if error_key

      Trier.new([ArgumentError, TypeError]) do |x|
        # strictly validate format of string, BigDecimal() doesn't do that
        Float(x)

        BigDecimal(x, digits)
      end.i18n_key(*error_keys).json_schema(type: 'string')
    end

    def array(error_key = nil)
      error_keys = ['.array', 'datacaster.errors.array']
      error_keys.unshift(error_key) if error_key

      check { |x| x.is_a?(Array) }.
        i18n_key(*error_keys).
        json_schema(type: 'array')
    end

    def float(error_key = nil)
      error_keys = ['.float', 'datacaster.errors.float']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(Float) }.i18n_key(*error_keys).
        json_schema(type: 'number', format: 'float')
    end

    def pattern(regexp, error_key = nil)
      error_keys = ['.pattern', 'datacaster.errors.pattern']
      error_keys.unshift(error_key) if error_key
      string(error_key) & check { |x| x.match?(regexp) }.i18n_key(*error_keys, reference: regexp.inspect).
        json_schema(pattern: regexp.inspect)
    end

    # 'hash' would be a bad method name, because it would override built in Object#hash
    def hash_value(error_key = nil)
      error_keys = ['.hash_value', 'datacaster.errors.hash_value']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(Hash) }.
        i18n_key(*error_keys).
        json_schema(type: 'object', additionalProperties: true)
    end

    def hash_with_symbolized_keys(error_key = nil)
      hash_value(error_key) & transform { |x| x.symbolize_keys }
    end

    def included_in(values, error_key: nil)
      error_keys = ['.included_in', 'datacaster.errors.included_in']
      error_keys.unshift(error_key) if error_key
      check { |x| values.include?(x) }.
        i18n_key(*error_keys, reference: values.map(&:to_s).join(', ')).
        json_schema(enum: values)
    end

    def integer(error_key = nil)
      error_keys = ['.integer', 'datacaster.errors.integer']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(Integer) }.i18n_key(*error_keys).
        json_schema(type: 'integer')
    end

    def integer32(error_key = nil)
      error_keys = ['.integer32', 'datacaster.errors.integer32']
      error_keys.unshift(error_key) if error_key
      integer(error_key) & check { |x| x.abs <= 2_147_483_647 }.i18n_key(*error_keys).
        json_schema(format: 'int32')
    end

    def maximum(max, error_key = nil, inclusive: true)
      subkey = 'lt'
      subkey += 'eq' if inclusive

      error_keys = [".maximum.#{subkey}", "datacaster.errors.maximum.#{subkey}"]

      error_keys.unshift(error_key) if error_key

      caster =
        if inclusive
          check { |x| x <= max }
        else
          check { |x| x < max }
        end

      numeric(error_key) & caster.i18n_key(*error_keys, max:)
    end

    def minimum(min, error_key = nil, inclusive: true)
      subkey = 'gt'
      subkey += 'eq' if inclusive

      error_keys = [".minimum.#{subkey}", "datacaster.errors.minimum.#{subkey}"]

      error_keys.unshift(error_key) if error_key

      caster =
        if inclusive
          check { |x| x >= min }
        else
          check { |x| x > min }
        end

      numeric(error_key) & caster.i18n_key(*error_keys, min:)
    end

    def string(error_key = nil)
      error_keys = ['.string', 'datacaster.errors.string']
      error_keys.unshift(error_key) if error_key
      check { |x| x.is_a?(String) }.i18n_key(*error_keys).
        json_schema(type: 'string')
    end

    def non_empty_string(error_key = nil)
      error_keys = ['.non_empty_string', 'datacaster.errors.non_empty_string']
      error_keys.unshift(error_key) if error_key
      string(error_key) & check { |x| !x.empty? }.i18n_key(*error_keys)
    end

    def uuid(error_key = nil)
      error_keys = ['.uuid', 'datacaster.errors.uuid']
      error_keys.unshift(error_key) if error_key
      pattern(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/, error_key).i18n_key(*error_keys)
    end

    # Form request types

    def iso8601(error_key = nil)
      error_keys = ['.iso8601', 'datacaster.errors.iso8601']
      error_keys.unshift(error_key) if error_key

      string(error_key) &
        try(catched_exception: [ArgumentError, TypeError]) { |x| DateTime.iso8601(x) }.
          i18n_key(*error_keys).
          json_schema(type: 'string', format: 'date-time')
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
      end.json_schema(oneOf: [
        { 'type' => 'string', 'enum' => ['true', 'false', '1', '0'] },
        { 'type' => 'boolean' },
      ])
    end

    def boolean(error_key = nil)
      error_keys = ['.boolean', 'datacaster.errors.boolean']
      error_keys.unshift(error_key) if error_key

      cast do |x|
        if [false, true].include?(x)
          Datacaster.ValidResult(x)
        else
          Datacaster.ErrorResult(I18nValues::Key.new(error_keys, value: x))
        end
      end.json_schema(type:'boolean')
    end

    def to_float(error_key = nil)
      error_keys = ['.to_float', 'datacaster.errors.to_float']
      error_keys.unshift(error_key) if error_key

      Trier.new([ArgumentError, TypeError]) do |x|
        Float(x)
      end.i18n_key(*error_keys).json_schema(type: 'number', format: 'float')
    end

    def to_integer(error_key = nil)
      error_keys = ['.to_integer', 'datacaster.errors.to_integer']
      error_keys.unshift(error_key) if error_key

      Trier.new([ArgumentError, TypeError]) do |x|
        Integer(x)
      end.i18n_key(*error_keys).json_schema(oneOf: [{ 'type' => 'string' }, { 'type' => 'number' }])
    end

    def optional_param(base)
      transform_if_present { |x| x == '' ? Datacaster::Absent.instance : x } & (absent | base)
    end
  end
end
