# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansout
        module RelObj
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__loan_obj_xrefs,
                destination: :loansout__rel_obj,
                lookup: :loans__out
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row, lkup: loans__out) { lkup.key?(row[:loanid]) }
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
