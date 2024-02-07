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
            Datacaster::Predefined.compare(caster_or_value)
          else
            Datacaster::Predefined.compare(caster_or_value.to_s) |
              Datacaster::Predefined.compare(caster_or_value.to_sym)
          end
        else
          Datacaster::Predefined.compare(caster_or_value)
        end

      clause = DefinitionDSL.expand(clause)

      self.class.new(@base, on_casters: @ons + [[caster, clause]], else_caster: @else, pick_key: @pick_key)
    end

    def else(else_caster)
      raise ArgumentError, "Datacaster: double else clause is not permitted", caller if @else
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
        result = check.with_runtime(runtime).(switch_result)
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

    def inspect
      "#<Datacaster::SwitchNode base: #{@base.inspect} on: #{@ons.inspect} else: #{@else.inspect} pick_key: #{@pick_key.inspect}>"
    end
  end
end
