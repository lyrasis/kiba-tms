# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectStatuses
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__object_statuses,
                destination: :prep__object_statuses
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: %i[inpermanentjurisdiction system]
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :objectstatus,
                find: '\(unknown\)',
                replace: 'unknown'
              transform Rename::Field, from: :objectstatus, to: :origstatus
              transform Replace::FieldValueWithStaticMapping,
                source: :origstatus,
                target: :objectstatus,
                mapping: Tms::ObjectStatuses.inventory_status_mapping,
                fallback_val: 'NEEDS MAPPING',
                delete_source: false
            end
          end
        end
      end
    end
  end
end
