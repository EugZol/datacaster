require 'dry/monads'

module Datacaster
  class Result
    include Dry::Monads[:result]

    def initialize(valid, value_or_errors)
      @value_or_errors = value_or_errors
      if !valid && !@value_or_errors.is_a?(Hash) && !@value_or_errors.is_a?(Array)
        @value_or_errors = Array(@value_or_errors)
      end

      @valid = !!valid
    end

    def valid?
      @valid
    end

    def value
      @valid ? @value_or_errors : nil
    end

    def value!
      raise "Tried to unwrap value of error result: #{inspect}" unless valid?
      value
    end

    def raw_errors
      @valid ? nil : @value_or_errors
    end

    def errors
      @errors ||= @valid ? nil : resolve_i18n(raw_errors)
    end

    def inspect
      if @valid
        "#<Datacaster::ValidResult(#{@value_or_errors.inspect})>"
      else
        "#<Datacaster::ErrorResult(#{@value_or_errors.inspect})>"
      end
    end

    def to_dry_result
      @valid ? Success(@value_or_errors) : Failure(errors)
    end

    private

    def resolve_i18n(o)
      case o
      when Array
        o.map { |x| resolve_i18n(x) }
      when Hash
        o.transform_values { |x| resolve_i18n(x) }
      when I18nValues::Base
        o.resolve
      else
        o
      end
    end
  end

  def self.ValidResult(object)
    if object.is_a?(Result)
      raise "Can't create valid result from error #{object.inspect}" unless object.valid?
      object
    else
      Result.new(true, object)
    end
  end

  def self.ErrorResult(object)
    if object.is_a?(Result)
      raise "Can't create error result from valid #{object.inspect}" if object.valid?
      object
    else
      Result.new(false, object)
    end
  end
end
