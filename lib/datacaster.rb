require_relative 'datacaster/result'
require_relative 'datacaster/version'

require_relative 'datacaster/absent'
require_relative 'datacaster/base'
require_relative 'datacaster/predefined'
require_relative 'datacaster/runner_context'
require_relative 'datacaster/terminator'

require_relative 'datacaster/array_schema'
require_relative 'datacaster/caster'
require_relative 'datacaster/checker'
require_relative 'datacaster/comparator'
require_relative 'datacaster/hash_mapper'
require_relative 'datacaster/hash_schema'
require_relative 'datacaster/message_keys_merger'
require_relative 'datacaster/transformer'
require_relative 'datacaster/trier'

require_relative 'datacaster/and_node'
require_relative 'datacaster/and_with_error_aggregation_node'
require_relative 'datacaster/or_node'
require_relative 'datacaster/then_node'

module Datacaster
  def self.schema(&block)
    raise "Expected block" unless block

    datacaster = RunnerContext.instance.instance_eval(&block)
    unless datacaster.is_a?(Base)
      raise "Datacaster instance should be returned from a block (e.g. result of 'hash_schema(...)' call)"
    end

    datacaster & Terminator::Raising.instance
  end

  def self.choosy_schema(&block)
    raise "Expected block" unless block

    datacaster = RunnerContext.instance.instance_eval(&block)
    unless datacaster.is_a?(Base)
      raise "Datacaster instance should be returned from a block (e.g. result of 'hash_schema(...)' call)"
    end

    datacaster & Terminator::Sweeping.instance
  end

  def self.partial_schema(&block)
    raise "Expected block" unless block

    datacaster = RunnerContext.instance.instance_eval(&block)
    unless datacaster.is_a?(Base)
      raise "Datacaster instance should be returned from a block (e.g. result of 'hash(...)' call)"
    end

    datacaster
  end

  def self.absent
    Datacaster::Absent.instance
  end
end
