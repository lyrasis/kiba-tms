# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansout
        module Ingest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loansout__prep,
                destination: :loansout__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[loanid borrower_extra borrowerscontact_org
                  borrowerscontact_extra]
              transform Delete::EmptyFields
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
