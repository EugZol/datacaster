module Datacaster
  module Config
    extend self

    attr_accessor :i18n_t
    attr_accessor :i18n_exists

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

    def i18n_t
      @i18n_t || ->(*args, **kwargs) { I18n.t(*args, **kwargs) }
    end

    def i18n_exists?
      @i18n_exists || ->(*args, **kwargs) { I18n.exists?(*args, **kwargs) }
    end

    def i18n_initialize!
      I18n.load_path += [__dir__ + '/../../config/locales/en.yml']
    end
  end
end
