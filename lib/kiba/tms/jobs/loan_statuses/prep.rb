# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanStatuses
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loan_statuses,
                destination: :prep__loan_statuses
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :loanstatus
            end
          end
        end
      end
    end
  end
end
