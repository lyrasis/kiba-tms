# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhLoanXrefs
        module NhrExhLoanout
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exh_loan_xrefs,
                destination: :exh_loan_xrefs__nhr_exh_loanout
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :loantype,
                value: 'loan out'
              transform Delete::FieldsExcept,
                fields: %i[exhibitionnumber loannumber item1_type]
              transform Rename::Fields, fieldmap: {
                exhibitionnumber: :item1_id,
                loannumber: :item2_id
              }
              transform Merge::ConstantValue,
                target: :item2_type,
                value: 'loansout'
            end
          end
        end
      end
    end
  end
end
