module Datacaster
  class Runtime
    def self.call(r, proc, *args)
      r.instance_exec(*args, &proc)
    end

    def initialize(parent = nil)
      @parent = parent
    end

    def method_missing(m, *args)
      return self.class.call(@parent, -> { public_send(m, *args) }) unless @parent.nil?
      raise RuntimeError.new("Method #{m.inspect} is not available in current runtime context")
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
