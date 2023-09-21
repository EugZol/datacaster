module Datacaster
  module ContextNodes
    class I18nKeysMapper < Datacaster::ContextNode
      def initialize(base, mapping)
        super(base)
        @mapping = mapping
        @from_keys = @mapping.keys
      end

      private

      def transform_errors(errors)
        return errors unless errors.length == 1 && errors.is_a?(Array)

        error = errors.first
        return errors unless error.is_a?(I18nValues::Key) || error.is_a?(I18nValues::DefaultKeys)

        keys = error.respond_to?(:keys) ? error.keys : [error.key]
        key_to_remap = keys.find { |x| @from_keys.include?(x) }
        return errors if key_to_remap.nil?
        new_key = @mapping[key_to_remap]

        [I18nValues::Key.new(new_key, error.args)]
      end
    end
  end
end
