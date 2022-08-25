# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectConPersonWithPositionNoInst
          # @private
          def process(row)
            return unless eligible?(row)
            
            row
          end
          
          private

          def eligible?(row)
            type_eligible?(row) && position_eligible?(row) && inst_eligible?(row)
          end

          def inst_eligible?(row)
            inst = row[:institution]
            true if inst.blank?
          end

          def position_eligible?(row)
            position = row[:position]
            true unless position.blank?
          end

          def type_eligible?(row)
            contype = row[:contype]
            return false if contype.blank?

            true if contype['Person']
          end
        end
      end
    end
  end
end
