module Datacaster
  module Config
    extend self

    attr_accessor :i18n_t
    attr_accessor :i18n_exists
    attr_accessor :i18n_module

    def add_predefined_caster(name, definition)
      case definition
      when Proc
        Predefined.define_method(name.to_sym, &definition)
      when Base
        Predefined.define_method(name.to_sym) { definition }
      else
        raise ArgumentError.new("Expected Datacaster defintion lambda or Datacaster instance")
      end
    end

    def i18n_t
      if @i18n_t.nil? && @i18n_module.nil?
        i18n_initialize!
      end
      @i18n_t || ->(*args, **kwargs) { @i18n_module.t(*args, **kwargs) }
    end

    def i18n_exists?
      if @i18n_t.nil? && @i18n_module.nil?
        i18n_initialize!
      end
      @i18n_exists || ->(*args, **kwargs) { @i18n_module.exists?(*args, **kwargs) }
    end

    def i18n_initialize!
      @i18n_module ||=
        if defined?(::I18n)
          I18n
        else
          SubstituteI18n
        end
      @i18n_module.load_path += [__dir__ + '/../../config/locales/en.yml']
    end
  end
end
