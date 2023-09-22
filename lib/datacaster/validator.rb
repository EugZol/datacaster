module Datacaster
  class Validator < Base
    @@validations = {}

    def self.create_active_model(validations)
      @@validations[validations] ||=
        Class.new do
          include ActiveModel::Validations

          attr_accessor :value

          def self.model_name
            ActiveModel::Name.new(self, nil, "ValidatorModel")
          end

          if validations.present?
            validates :value, validations
          end
        end.new
    end

    def initialize(validations)
      require 'active_model'

      if Config.i18n_module == SubstituteI18n
        raise NotImplementedError, "Using ActiveModel validations requires ruby-i18n or another i18n gem instead of datacaster's built-in", caller
      end
      @validator = self.class.create_active_model(validations)
    end

    def cast(object, runtime:)
      @validator.value = object
      @validator.valid? ? Datacaster.ValidResult(object) : Datacaster.ErrorResult(@validator.errors[:value])
    end

    def inspect
      "#<Datacaster::Validator>"
    end
  end
end
