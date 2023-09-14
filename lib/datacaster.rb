require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect('definition_dsl' => 'DefinitionDSL')
loader.setup

require_relative 'datacaster/result'

module Datacaster
  extend self

  def schema(&block)
    ContextNodes::StructureCleaner.new(build_schema(&block), :fail)
  end

  def choosy_schema(&block)
    ContextNodes::StructureCleaner.new(build_schema(&block), :remove)
  end

  def partial_schema(&block)
    ContextNodes::StructureCleaner.new(build_schema(&block), :pass)
  end

  def absent
    Datacaster::Absent.instance
  end

  private

  def build_schema(&block)
    raise "Expected block" unless block

    datacaster = DefinitionDSL.eval(&block)

    unless datacaster.is_a?(Base)
      raise "Datacaster instance should be returned from a block (e.g. result of 'hash_schema(...)' call)"
    end

    datacaster
  end
end
