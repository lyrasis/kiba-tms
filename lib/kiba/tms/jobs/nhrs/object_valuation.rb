# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module ObjectValuation
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :valuationcontrols__all,
                destination: :nhrs__object_valuation
              },
              transformer: [
                xforms,
                config.finalize_xforms
              ]
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber valuationcontrolrefnumber]
              transform Rename::Fields, fieldmap: {
                objectnumber: :item1_id,
                valuationcontrolrefnumber: :item2_id
              }
              transform Merge::ConstantValues, constantmap: {
                item1_type: "collectionobjects",
                item2_type: "valuationcontrols"
              }
            end
          end
        end
      end
    end
  end
end
