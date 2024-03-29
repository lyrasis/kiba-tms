# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansin
        module Ingest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loansin__prep,
                destination: :loansin__ingest
              },
              transformer: [
                xforms,
                config.pre_ingest_xforms
              ].compact
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :loanid
              transform Delete::EmptyFields
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
