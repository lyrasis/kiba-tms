# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__alt_nums,
                destination: :prep__alt_nums
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames
              transform Rename::Fields, fieldmap: {
                id: :recordid,
                altnumid: :sort
              }
              transform Clean::RegexpFindReplaceFieldVals, fields: :description, find: '\\\\n', replace: ''
              transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '^(%CR%%LF%)+', replace: ''
              transform Clean::RegexpFindReplaceFieldVals, fields: :all, find: '(%CR%%LF%)+$', replace: ''
            end
          end
        end
      end
    end
  end
end
