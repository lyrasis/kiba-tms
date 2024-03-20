# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Nhrs
        module ExhibitionLoaninIndirect
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exh_obj_loan_obj_xrefs,
                destination: :nhrs__exhibition_loanin_indirect
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :loantype,
                value: "loan in"
              transform Delete::FieldsExcept,
                fields: %i[exhibitionnumber loannumber]
              transform Rename::Fields, fieldmap: {
                exhibitionnumber: :item1_id,
                loannumber: :item2_id
              }
              transform Merge::ConstantValue,
                target: :item1_type,
                value: "exhibitions"
              transform Merge::ConstantValue,
                target: :item2_type,
                value: "loansin"
            end
          end
        end
      end
    end
  end
end
