require 'bigdecimal'
require 'date'

module Datacaster
  class DefinitionDSL
    include Datacaster::Predefined
    include Dry::Monads[:result]

    # Translates hashes like {a: <IntegerChecker>} to <HashSchema {a: <IntegerChecker>}>
    #   and arrays like [<IntegerChecker>] to <ArraySchema <IntegerChecker>>
    def self.expand(definition)
      case definition
      when Datacaster::Base
        definition
      when Array
        if definition.length != 1
          raise ArgumentError.new("Datacaster: DSL array definitions must have exactly 1 element in the array, e.g. [integer]")
        end
        ArraySchema.new(expand(definition.first))
      when Hash
        HashSchema.new(definition.transform_values { |x| expand(x) })
      else
        return definition if definition.respond_to?(:call)
        raise ArgumentError.new("Datacaster: Unknown definition #{definition.inspect}, which doesn't respond to #call")
      end
    end

    def self.eval(&block)
      new.instance_exec(&block)
    end

    def method_missing(m, *args)
      arg_string = args.empty? ? "" : "(#{args.map(&:inspect).join(', ')})"
      raise RuntimeError, "Datacaster: unknown definition '#{m}#{arg_string}'", caller
    end
  end
end
