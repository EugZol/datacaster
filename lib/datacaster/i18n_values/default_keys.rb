require 'set'

module Datacaster
  module I18nValues
    class DefaultKeys < Base
      attr_reader :keys

      def initialize(keys, args = {})
        @keys = keys.to_set
        @args = args
      end

      def ==(other)
        super && @keys = other.keys
      end

      def inspect
        "#<#{self.class.name}(#{@keys.join(', ')}) #{@args.inspect}>"
      end
    end
  end
end
