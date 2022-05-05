# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module EMailTypes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__email_types,
                destination: :prep__email_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :emailtype,
                match: '\([Nn]ot [Aa]ssigned\)'
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :emailtype,
                find: 'Home',
                replace: 'personal' 
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :emailtype,
                find: 'Work',
                replace: 'business' 
            end            
          end
        end
      end
    end
  end
end
