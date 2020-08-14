require 'dry/monads'

module Datacaster
  class Result
    attr_accessor :meta
    include Dry::Monads[:result]

    def initialize(valid, value_or_errors, meta: nil)
      @value_or_errors = value_or_errors
      @valid = !!valid
      @meta = meta || {}
    end

    def valid?
      @valid
    end

    def value
      @valid ? @value_or_errors : nil
    end

    def errors
      unless @value_or_errors.is_a?(Hash) || @value_or_errors.is_a?(Array)
        @value_or_errors = Array(@value_or_errors)
      end
      @valid ? nil : @value_or_errors
    end

    def inspect
      if @valid
        "#<Datacaster::ValidResult(#{@value_or_errors.inspect})>"
      else
        "#<Datacaster::ErrorResult(#{@value_or_errors.inspect})>"
      end
    end

    def to_dry_result
      @valid ? Success(@value_or_errors) : Failure(@value_or_errors)
    end
  end

  def self.ValidResult(object, meta: nil)
    if object.is_a?(Result)
      raise "Can't create valid result from error #{object.inspect}" unless object.valid?
      object.meta = meta if meta
      object
    else
      Result.new(true, object, meta: meta)
    end
  end

  def self.ErrorResult(object, meta: nil)
    if object.is_a?(Result)
      raise "Can't create error result from valid #{object.inspect}" if object.valid?
      object.meta = meta if meta
      object
    else
      Result.new(false, object, meta: meta)
    end
  end
end
