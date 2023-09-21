module Datacaster
  class Runtime
    def self.call(r, proc, *args)
      r.instance_exec(*args, &proc)
    end

    def self.send_to_parent(r, m, *args, &block)
      parent = r.instance_variable_get(:@parent)
      not_found!(m) if parent.nil?
      call(parent, -> { public_send(m, *args, &block) })
    end

    def self.not_found!(m)
      raise NoMethodError.new("Method #{m.inspect} is not available in current runtime context")
    end

    def initialize(parent = nil)
      @parent = parent
    end

    def method_missing(m, *args, &block)
      self.class.send_to_parent(self, m, *args, &block)
    end

    def respond_to_missing?(m, include_private = false)
      !@parent.nil? && @parent.respond_to?(m, include_private)
    end

    def inspect
      "#<#{self.class.name} parent: #{@parent.inspect}>"
    end

    def to_s
      inspect
    end

    def Success(v)
      Datacaster.ValidResult(v)
    end

    def Failure(v)
      Datacaster.ErrorResult(v)
    end
  end
end
