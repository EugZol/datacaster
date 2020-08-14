require 'active_model'

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

    def initialize(validations, name)
      @name = name
      @validator = self.class.create_active_model(validations)
    end

    def call(object)
      intermediary_result = super(object)
      object = intermediary_result.value

      @validator.value = object
      @validator.valid? ? Datacaster.ValidResult(object) : Datacaster.ErrorResult(@validator.errors[:value])
    end

    def inspect
      "#<Datacaster::#{@name}Validator>"
    end
  end
end
