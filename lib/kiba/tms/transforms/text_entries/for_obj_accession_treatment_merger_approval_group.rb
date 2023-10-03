# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjAccessionTreatmentMergerApprovalGroup
          include TreatmentMergeable

          def initialize
            @delim = Tms.delim
          end

          def process(row, mergerow)
            vals = {
              te_approvalgroup: mergerow[:org_author],
              te_approvalindividual: mergerow[:person_author],
              te_approvaldate: mergerow[:textdate],
              te_approvalnote: mergerow[:textentry],
              te_approvalstatus: mergerow[:texttype]
            }.transform_values { |val| val.blank? ? "%NULLVALUE%" : val }

            fresh?(row) ? add(row, vals) : append(row, vals)
            row
          end

          private

          attr_reader :delim

          def fresh?(row)
            true unless row.key?(:te_approvalstatus)
          end

          def add(row, vals)
            row.merge!(vals)
          end

          def append(row, vals)
            vals.each { |key, val| row[key] = [row[key], val].join(delim) }
            row
          end
        end
      end
    end
  end
end
