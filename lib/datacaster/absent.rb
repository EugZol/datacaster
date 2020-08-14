require 'singleton'

module Datacaster
  class Absent
    include Singleton

    def blank?
      true
    end

    def inspect
      "#<Datacaster.absent>"
    end

    def present?
      false
    end
  end
end
