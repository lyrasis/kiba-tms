# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objectexit
        module Ingest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_deaccession__shape,
                destination: :objectexit__ingest
              },
              transformer: get_xforms
            )
          end

          def get_xforms
            base = [xforms]
            base.unshift(config.sample_xforms) if config.sampleable?
            base.compact
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
