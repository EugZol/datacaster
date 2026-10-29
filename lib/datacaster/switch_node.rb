module Datacaster
  class SwitchNode < Base
    def initialize(base = nil, on_casters: [], else_caster: nil, pick_key: nil)
      @base = base
      @pick_key = pick_key

      if Datacaster::Utils.pickable?(@base)
        unless @pick_key.nil?
          raise RuntimeError, "pick_key expected to be nil because #{@base.inspect} is pickable"
        end
        @pick_key = base
        @base = Datacaster::Predefined.pick(base)
      end

      if !@base.nil? && !Datacaster.instance?(@base)
        raise RuntimeError, "provide a Datacaster::Base instance, a hash key, or an array of keys to switch(...) caster", caller
      end

      @ons = on_casters
      @else = else_caster
    end

    def on(caster_or_value, clause, strict: false)
      caster =
        case caster_or_value
        when Datacaster::Base
          caster_or_value
        when String, Symbol
          if strict
            Datacaster::Predefined.compare(caster_or_value).json_schema { {"type" => "string", "enum" => [caster_or_value.to_s]} }
          else
            (
              Datacaster::Predefined.compare(caster_or_value.to_s) |
                Datacaster::Predefined.compare(caster_or_value.to_sym)
            ).json_schema { {"type" => "string", "enum" => [caster_or_value.to_s]} }
          end
        else
          Datacaster::Predefined.compare(caster_or_value)
        end

      clause = DefinitionDSL.expand(clause)

      self.class.new(@base, on_casters: @ons + [[caster, clause]], else_caster: @else, pick_key: @pick_key)
    end

    def else(else_caster)
      raise ArgumentError, "Datacaster: double else clause is not permitted", caller if @else
      else_caster = DefinitionDSL.expand(else_caster)
      self.class.new(@base, on_casters: @ons, else_caster: else_caster, pick_key: @pick_key)
    end

    def cast(object, runtime:)
      if @ons.empty?
        raise RuntimeError, "switch caster requires at least one 'on' statement: switch(...).on(condition, cast)", caller
      end

      if @base.nil?
        switch_result = object
      else
        switch_result = @base.with_runtime(runtime).(object)
        return switch_result unless switch_result.valid?
        switch_result = switch_result.value
      end

      @ons.each do |check, clause|
        result = runtime.record_checks_on_success { check.with_runtime(runtime).(switch_result) }
        next unless result.valid?

        runtime.checked_key!(@pick_key) if !@pick_key.nil? && !@pick_key.is_a?(Array)
        return clause.with_runtime(runtime).(object)
      end

      # all 'on'-s have failed
      return @else.with_runtime(runtime).(object) if @else

      Datacaster.ErrorResult(
        I18nValues::Key.new(['.switch', 'datacaster.errors.switch'], value: object)
      )
    end

    def to_json_schema
      if @ons.empty?
        raise RuntimeError, "switch caster requires at least one 'on' statement: switch(...).on(condition, cast)", caller
      end

      base = @base.to_json_schema

      schema_result = @ons.map { |on|
        base.apply(on[0].to_json_schema).without_focus.apply(on[1].to_json_schema)
      }

      if @else
        schema_result << @else.to_json_schema
      end

      JsonSchemaResult.new( "oneOf" => schema_result )
    end

    def to_json_schema_attributes
      super.merge(
        extendable: true,
        remaped:
          [@base, @else, *@ons.map(&:last)].compact.reduce({}) do |result, caster|
            result.merge(caster.to_json_schema_attributes[:remaped])
          end
      )
    end

    def inspect
      "#<Datacaster::SwitchNode base: #{@base.inspect} on: #{@ons.inspect} else: #{@else.inspect} pick_key: #{@pick_key.inspect}>"
    end
  end
end
