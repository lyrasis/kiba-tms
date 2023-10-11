# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Collectionobjects
        module ForIngest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__shape,
                destination: :collectionobjects__for_ingest
              },
              transformer: get_xforms
            )
          end

          def get_xforms
            return [xforms] unless config.sampleable?

            [config.sample_xforms, xforms]
          end

          def xforms
            Kiba.job_segment do
              transform Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
