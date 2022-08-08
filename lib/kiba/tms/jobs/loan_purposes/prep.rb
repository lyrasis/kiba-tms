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
              transform do |row|
                purpose = row[:loanpurpose]
                next if Tms::LoanPurposes.unused_values.any?(purpose)

                row
              end
            end
          end
        end
      end
    end
  end
end
