module Datacaster
  module Config
    extend self

    def add_predefined_caster(name, definition)
      caster =
        case definition
        when Proc
          Datacaster.partial_schema(&definition)
        when Base
          definition
        else
          raise ArgumentError.new("Expected Datacaster defintion lambda or Datacaster instance")
        end

      Predefined.define_method(name.to_sym) { caster }
    end
  end
end
