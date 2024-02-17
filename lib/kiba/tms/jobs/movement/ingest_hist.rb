# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Movement
        module IngestHist
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__lmi,
                destination: :movement__ingest_hist
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :current
              transform Delete::Fields,
                fields: %i[objectnumber current]
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
