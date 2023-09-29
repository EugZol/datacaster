require 'yaml'

module Datacaster
  module SubstituteI18n
    @load_path = []

    def self.exists?(key)
      !fetch(key).nil?
    end

    def self.fetch(key)
      keys = [locale] + key.split('.')

      @translations.each do |hash|
        result = hash.dig(*keys)
        return result unless result.nil?
      end
      nil
    end

    def self.load_path
      @load_path
    end

    def self.load_path=(array)
      @load_path = array
      @translations = array.map { |x| YAML.load_file(x) }
    end

    def self.locale
      'en'
    end

    def self.locale=(*)
      raise NotImplementedError.new("Setting locale is not supported, use ruby-i18n instead of datacaster's built-in")
    end

    def self.t(key, **args)
      string = fetch(key)
      return "Translation missing #{key}" unless string

      args.each do |from, to|
        string = string.gsub("%{#{from}}", to.to_s)
      end
      string
    end
  end
end
