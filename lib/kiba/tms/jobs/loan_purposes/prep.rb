# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanPurposes
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loan_purposes,
                destination: :prep__loan_purposes
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :loanpurpose

              transform Replace::FieldValueWithStaticMapping,
                source: :loanpurpose,
                mapping: Tms::LoanPurposes.mappings
            end
          end
        end
      end
    end
  end
end
