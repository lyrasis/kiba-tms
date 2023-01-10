# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Relationships
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__relationships,
                destination: :prep__relationships
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner
              transform Tms::Transforms::TmsTableNames
            end
          end
        end
      end
    end
  end
end
