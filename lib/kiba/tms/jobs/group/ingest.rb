# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Group
        module Ingest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :packages__shaped,
                destination: :group__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: :packageid

              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
