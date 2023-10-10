module Datacaster
  class SwitchNode < Base
    def initialize(base = nil, on_casters = [], else_caster = nil)
      @base = base

      if Datacaster::Utils.pickable?(@base)
        @base = Datacaster::Predefined.run { checked_key!(base) } &
          Datacaster::Predefined.pick(base)
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
            Datacaster::Predefined.compare(caster_or_value)
          else
            (
              Datacaster::Predefined.compare(caster_or_value.to_s) |
                Datacaster::Predefined.compare(caster_or_value.to_sym)
            ).json_schema { {"enum" => [caster_or_value.to_s]} }
          end
        else
          Datacaster::Predefined.compare(caster_or_value)
        end

      clause = DefinitionDSL.expand(clause)

      self.class.new(@base, @ons + [[caster, clause]], @else)
    end

    def else(else_caster)
      raise ArgumentError, "Datacaster: double else clause is not permitted", caller if @else
      self.class.new(@base, @ons, else_caster)
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
        result = check.with_runtime(runtime).(switch_result)
        next unless result.valid?

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

      JsonSchemaResult.new(
        "oneOf" => @ons.map { |on|
          base.apply(on[0].to_json_schema).without_focus.apply(on[1].to_json_schema)
        }
      )
    end

    def inspect
      "#<Datacaster::SwitchNode base: #{@base.inspect} on: #{@ons.inspect} else: #{@else.inspect}>"
    end
  end
end
