# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      module NameTypeCleanupable
        def self.extended(mod)
          self.define_ntc_needed(mod)
        end

        def is_name_type_cleanupable?
          true
        end

        def ntc_targets
          Tms::NameTypeCleanup.targets
        end

        # METHODS FOR EXTENDING
        def self.define_ntc_needed(mod)
          meth = :ntc_needed?
          return if mod.respond_to?(meth)

          warn("Need to set :#{meth} returning Boolean value for #{mod}")
          mod.define_method(meth){ false }
        end
        private_class_method :define_ntc_needed
      end
    end
  end
end
