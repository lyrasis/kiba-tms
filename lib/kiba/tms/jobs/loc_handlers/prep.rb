# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocHandlers
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loc_handlers,
                destination: :prep__loc_handlers
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :handler
            end
          end
        end
      end
    end
  end
end
