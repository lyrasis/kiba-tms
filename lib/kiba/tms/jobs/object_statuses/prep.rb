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
              if Tms::ObjectStatuses.omitting_fields?
                transform Delete::Fields, fields: Tms::ObjectStatuses.omitted_fields
              end
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :objectstatus,
                find: '\(unknown\)',
                replace: 'unknown'
              transform Rename::Field, from: :objectstatus, to: :origstatus
              transform Replace::FieldValueWithStaticMapping,
                source: :origstatus,
                target: :objectstatus,
                mapping: Tms::ObjectStatuses.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
