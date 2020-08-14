require 'bigdecimal'
require 'date'

module Datacaster
  class RunnerContext
    include Singleton
    include Datacaster::Predefined
    include Dry::Monads[:result]

    alias_method :array_of, :array_schema

    def m(definition)
      raise 'not implemented'
    end

    def method_missing(m, *args)
      arg_string = args.empty? ? '' : "(#{args.map(&:inspect).join(', ')})"
      raise "Datacaster: unknown definition '#{m}#{arg_string}'"
    end
  end
end
