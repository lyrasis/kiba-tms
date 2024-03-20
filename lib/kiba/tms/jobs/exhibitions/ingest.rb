# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module Ingest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :exhibitions__merge_venue_details,
                destination: :exhibitions__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: :exhibitionid

              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
