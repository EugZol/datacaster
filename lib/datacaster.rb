require 'zeitwerk'
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect('definition_dsl' => 'DefinitionDSL')
loader.setup

require_relative 'datacaster/result'

module Datacaster
  extend self

  def schema(i18n_scope: nil, &block)
    ContextNodes::StructureCleaner.new(build_schema(i18n_scope: i18n_scope, &block), :fail)
  end

  def choosy_schema(i18n_scope: nil, &block)
    ContextNodes::StructureCleaner.new(build_schema(i18n_scope: i18n_scope, &block), :remove)
  end

  def partial_schema(i18n_scope: nil, &block)
    ContextNodes::StructureCleaner.new(build_schema(i18n_scope: i18n_scope, &block), :pass)
  end

  def absent
    Datacaster::Absent.instance
  end

  def instance?(object)
    object.is_a?(Mixin)
  end

  private

  def build_schema(i18n_scope: nil, &block)
    raise "Expected block" unless block

    datacaster = DefinitionDSL.eval(&block)

    unless Datacaster.instance?(datacaster)
      raise "Datacaster instance should be returned from a block (e.g. result of 'hash_schema(...)' call)"
    end

    datacaster = datacaster.i18n_scope(i18n_scope) if i18n_scope

    datacaster
  end
end
