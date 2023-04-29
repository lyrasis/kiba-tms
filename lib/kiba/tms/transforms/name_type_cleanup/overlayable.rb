# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        module Overlayable
          def eligible?(row)
            if target.is_a?(Symbol)
              eligible_symbol?(row)
            elsif target.is_a?(Hash)
              eligible_hash?(row)
            else
              fail(TypeError, "target must be Symbol or Hash")
            end
          end
          private :eligible?

          def eligible_symbol?(row)
            return true if row.key?(target)
          end
          private :eligible_symbol?

          def eligible_hash?(row)
            reltype = row[:relation_type]
            return false if reltype.blank?
            return false unless target.key?(reltype)
            return false unless row.key?(target[reltype])

            true
          end
          private :eligible_hash?

          def row_target(row)
            if target.is_a?(Symbol)
              target
            else
              target[row[:relation_type]]
            end
          end
          private :row_target
        end
      end
    end
  end
end
