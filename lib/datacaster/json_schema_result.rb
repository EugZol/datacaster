module Datacaster
  class JsonSchemaResult < Hash
    def initialize(from = {}, focus = nil)
      merge!(from)

      if from.is_a?(self.class)
        @focus = from.focus
      else
        @focus = []
      end
      if focus == false || @focus == false
        @focus = false
        return
      end
      @focus << focus if focus
      @target = self
      @focus.each { |k| @target = @target['properties'][k] }
    end

    def with_focus_key(key)
      result = apply(
        "type" => "object",
        "properties" => {key => {}}
      )
      self.class.new(result, key)
    end

    def without_focus
      self.class.new(self).reset_focus
    end

    def apply(other)
      return self if other.nil? || other.empty?
      return self if @focus.last == false
      return JsonSchemaResult.new(other) if empty?

      unless @focus.empty?
        return with_updated_target(JsonSchemaResult.new(@target).apply(other))
      end

      result = self.class.new({})

      if self['required'] || other['required']
        result['required'] =
          ((self['required'] || []).to_set |
            (other['required'] || []).to_set).to_a
      end

      nested =
        if self['properties'] && (other['items'] || self['items']) ||
          self['items'] && (self['properties'] || other['properties']) ||
          other['items'] && other['properties']
          raise RuntimeError, "can't merge json schemas due to wrong items/properties combination " \
            "for #{self.inspect} and #{other.inspect}", caller
        elsif self['properties'] || other['properties']
          'properties'
        elsif self['items'] || other['items']
          'items'
        else
          nil
        end

      if nested
        result[nested] = {}

        keys =
          (self[nested] || {}).keys +
          (other[nested] || {}).keys
        keys = keys.to_set
        keys.each do |k|
          one_k = self[nested] && self[nested][k] || {}
          two_k = other[nested] && other[nested][k] || {}
          result[nested][k] = self.class.new(one_k).apply(two_k)
        end
      end

      if self['description'] || other['description']
        result['description'] = other['description'] || self['description']
      end

      (self.keys + other.keys - %w(required properties items description)).to_set.each do |k|
        if self[k] && other[k] && self[k] != other[k]
          raise RuntimeError, "can't merge json schemas due to conflicting field #{k} for " \
            "#{inspect} and #{other.inspect}", caller
        end

        result[k] = other[k] || self[k]
      end

      result
    end

    protected

    def focus
      @focus
    end

    def reset_focus
      @focus = []
      @target = self
      self
    end

    private

    def with_updated_target(target)
      result = self.class.new(self)
      nested =
        @focus[0..-2].reduce(result) do |result, k|
          result['properties'][k] = result['properties'][k].dup
          result['properties'][k]
        end
      nested['properties'][@focus[-1]] = target
      result
    end
  end
end
