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
              transform Tms::Transforms::TmsTableNames
              transform Tms::Transforms::Relationships::AddLabel
            end
          end
        end
      end
    end
  end
end
