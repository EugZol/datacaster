module Datacaster
  class AroundNode < Base
    def initialize(around = nil, &block)
      raise "Expected block" unless block_given?

      @around = around
      @run = block
    end

    def around(*casters)
      if @around
        raise ArgumentError, "only one call to .around(...) is expect, tried to call second time", caller
      end

      unless casters.all? { |x| Datacaster.instance?(x) }
        raise ArgumentError, "provide datacaster instance to .around(...)", caller
      end

      caster = casters.length == 1 ? casters[0] : Datacaster::Predefined.steps(*casters)

      self.class.new(caster, &@run)
    end

    def cast(object, runtime:)
      unless @around
        raise ArgumentError, "call .around(caster) beforehand", caller
      end
    end

    def inspect
      "#<#{self.class.name}>"
    end
  end
end
