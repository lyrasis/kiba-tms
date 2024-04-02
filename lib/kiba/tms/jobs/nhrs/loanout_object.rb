# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module LoanoutObject
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__loan_obj_xrefs,
                destination: :nhrs__loanout_object
              },
              transformer: [xforms, config.finalize_xforms]
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :loantype,
                value: "loan out"

              transform Delete::FieldsExcept,
                fields: %i[loannumber objectnumber]
              transform Rename::Fields,
                fieldmap: {loannumber: :item2_id, objectnumber: :item1_id}
              transform Merge::ConstantValues,
                constantmap: {
                  item2_type: "loansout",
                  item1_type: "collectionobjects"
                }
            end
          end
        end
      end
    end
  end
end
