module Datacaster
  module Config
    extend self

    attr_accessor :i18n_backend

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

    def i18n_backend
      @i18n_backend || I18n.method(:t)
    end

    def i18n_initialize!
      I18n.load_path += [__dir__ + '/../../config/locales/en.yml']
    end
  end
end
