module Datacaster
  class Base
    def self.merge_errors(left, right)
      add_error_to_base = ->(hash, error) {
        hash[:base] ||= []
        hash[:base] = merge_errors(hash[:base], error)
        hash
      }

      return [] if left.nil? && right.nil?
      return right if left.nil?
      return left if right.nil?

      result = case [left.class, right.class]
      when [Array, Array]
        left | right
      when [Array, Hash]
        add_error_to_base.(right, left)
      when [Hash, Hash]
        (left.keys | right.keys).map do |k|
          [k, merge_errors(left[k], right[k])]
        end.to_h
      when [Hash, Array]
        add_error_to_base.(left, right)
      else
        raise ArgumentError.new("Expected failures to be Arrays or Hashes, left: #{left.inspect}, right: #{right.inspect}")
      end

      result
    end

    def &(other)
      AndNode.new(self, other)
    end

    def |(other)
      OrNode.new(self, other)
    end

    def *(other)
      AndWithErrorAggregationNode.new(self, other)
    end

    def then(other)
      ThenNode.new(self, other)
    end

    def call(object)
      Datacaster.ValidResult(object)
    end

    def inspect
      "#<Datacaster::Base>"
    end

    private

    # Translates hashes like {a: <IntegerChecker>} to <HashSchema {a: <IntegerChecker>}>
    #   and arrays like [<IntegerChecker>] to <ArraySchema <IntegerChecker>>
    def shortcut_definition(definition)
      case definition
      when Datacaster::Base
        definition
      when Array
        if definition.length != 1
          raise ArgumentError.new("Datacaster: shorcut array definitions must have exactly 1 element in the array, e.g. [integer]")
        end
        ArraySchema.new(definition.first)
      when Hash
        HashSchema.new(definition)
      else
        return definition if definition.respond_to?(:call)
        raise ArgumentError.new("Datacaster: Unknown definition #{definition.inspect}, which doesn't respond to #call")
      end
    end
  end
end
