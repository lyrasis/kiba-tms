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
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              unless config.merged_data_cleaners.empty?
                transform Tms::Transforms::List,
                  xforms: config.merged_data_cleaners
              end

              unless config.merged_data_shapers.empty?
                transform Tms::Transforms::List,
                  xforms: config.merged_data_shapers
              end

              unless config.post_merged_prep_xforms.empty?
                transform Tms::Transforms::List,
                  xforms: config.post_merged_prep_xforms
              end

              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
