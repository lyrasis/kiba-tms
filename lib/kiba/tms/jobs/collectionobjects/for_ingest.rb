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
                source: :objects__authorities_merged,
                destination: :collectionobjects__for_ingest
              },
              transformer: get_xforms
            )
          end

          def get_xforms
            base = [xforms, config.final_xforms]
            base.unshift(config.sample_xforms) if config.sampleable?
            base.compact
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :objectid
              transform Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
