module Datacaster
  module Utils
    extend self

    def merge_errors(left, right)
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
  end
end
