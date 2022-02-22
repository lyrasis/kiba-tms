# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectStatuses
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__object_statuses,
              destination: :prep__object_statuses
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields, fields: %i[inpermanentjurisdiction system]
            transform Clean::RegexpFindReplaceFieldVals,
              fields: :objectstatus,
              find: '\(unknown\)',
              replace: 'unknown'
          end
        end
      end
    end
  end
end
