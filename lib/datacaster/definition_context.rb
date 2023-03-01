require 'bigdecimal'
require 'date'

module Datacaster
  class DefinitionContext
    include Datacaster::Predefined
    include Dry::Monads[:result]

    attr_accessor :context

    def m(_definition)
      raise "not implemented"
    end

    def method_missing(m, *args)
      arg_string = args.empty? ? "" : "(#{args.map(&:inspect).join(', ')})"
      raise "Datacaster: unknown definition '#{m}#{arg_string}'"
    end
  end
end
