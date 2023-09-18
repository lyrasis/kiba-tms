# frozen_string_literal: true

# Mixin module providing consistent methods for config modules that
#   represent CollectionSpace target record types
#
# ## Implementation details
#
# Modules mixing this in must:
#
# - `extend Tms::Mixins::CsTargetable`
#
# This module should be mixed in AFTER any other mixins
module Kiba
  module Tms
    module Mixins
      module CsTargetable
        def self.extended(mod)
          define_used_method(mod)
        end

        def self.define_used_method(mod)
          return if mod.respond_to?(:used?)

          str = <<~CFG
            def used?
              Tms.cspace_target_records.include?(
                name.delete_prefix("Kiba::Tms::")
              )
            end
          CFG

          mod.instance_eval(str, __FILE__, __LINE__)
        end
      end
    end
  end
end
