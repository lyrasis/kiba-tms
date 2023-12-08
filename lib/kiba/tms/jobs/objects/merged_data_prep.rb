# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module MergedDataPrep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__external_data_merged,
                destination: :objects__merged_data_prep
              },
              transformer: [
                config.merged_data_cleaners,
                config.merged_data_shapers,
                config.post_merged_prep_xforms,
                consistent
              ].compact
            )
          end

          def consistent
            Kiba.job_segment do
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
