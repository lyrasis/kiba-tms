# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module PhoneTypes
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__phone_types,
                destination: :prep__phone_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :phonetype
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :phonetype,
                find: "Home",
                replace: "home" 
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :phonetype,
                find: "Cell",
                replace: "mobile"
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :phonetype,
                find: "Office",
                replace: "business"
            end
          end
        end
      end
    end
  end
end
