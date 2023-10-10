module Datacaster
  class AndNode < Base
    def initialize(*casters)
      @casters = casters
    end

    def cast(object, runtime:)
      Datacaster.ValidResult(
        @casters.reduce(object) do |result, caster|
          caster_result = caster.with_runtime(runtime).(result)
          return caster_result unless caster_result.valid?
          caster_result.value
        end
      )
    end

    def to_json_schema
      @casters.reduce(JsonSchemaResult.new) do |result, caster|
        result.apply(caster.to_json_schema)
      end
    end

    def inspect
      "#<Datacaster::AndNode casters: #{@casters.inspect}>"
    end
  end
end
