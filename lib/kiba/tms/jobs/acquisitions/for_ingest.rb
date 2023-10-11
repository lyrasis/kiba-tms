# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module ForIngest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acquisitions__all,
                destination: :acquisitions__for_ingest
              },
              transformer: get_xforms
            )
          end

          def get_xforms
            return [xforms] unless config.sampleable?

            [config.sample_xforms, xforms]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              transform Delete::FieldsExcept,
                fields: config.cs_fields[Tms.cspace_profile]

              transform Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
