require 'set'

module Datacaster
  module Utils
    extend self

    def deep_merge(first, second)
      merger = proc { |_, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : Array === v1 && Array === v2 ? v1 | v2 : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
      first.merge(second.to_h, &merger)
    end

    # Merges checked schemas key by key: a key accepted whole (true) on either side
    # stays accepted whole, nested checks on both sides combine
    def merge_checks!(into, from)
      into.merge!(from) { |_, a, b| a == true || b == true ? true : merge_checks!(a, b) }
    end

    def deep_freeze(value, copy: true)
      Ractor.make_shareable(value, copy:)
    end

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

    def pickable?(value)
      is_literal = ->(v) { [String, Symbol, Integer].any? { |c| v.is_a?(c) } }
      is_literal.(value) ||
        value.is_a?(Array) && !value.empty? && value.all? { |v| is_literal.(v) }
    end
  end
end
