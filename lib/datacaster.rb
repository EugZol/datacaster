require_relative 'datacaster/result'
require_relative 'datacaster/version'

require_relative 'datacaster/absent'
require_relative 'datacaster/base'
require_relative 'datacaster/predefined'
require_relative 'datacaster/definition_context'
require_relative 'datacaster/terminator'
require_relative 'datacaster/config'

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
  extend self

  def schema(&block)
    build_schema(Terminator::Raising.instance, &block)
  end

  def choosy_schema(&block)
    build_schema(Terminator::Sweeping.instance, &block)
  end

  def partial_schema(&block)
    build_schema(nil, &block)
  end

  def absent
    Datacaster::Absent.instance
  end

  private

  def build_schema(terminator, &block)
    raise "Expected block" unless block

    definition_context = DefinitionContext.new

    datacaster = definition_context.instance_exec(&block)

    unless datacaster.is_a?(Base)
      raise "Datacaster instance should be returned from a block (e.g. result of 'hash_schema(...)' call)"
    end

    datacaster = (datacaster & terminator) if terminator
    datacaster.set_definition_context(definition_context)
    datacaster
  end
end
