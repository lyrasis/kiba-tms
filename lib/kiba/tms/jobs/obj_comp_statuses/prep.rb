# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjCompStatuses
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_comp_statuses,
                destination: :prep__obj_comp_statuses
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              if Tms::ObjCompStatuses.omitting_fields?
                transform Delete::Fields, fields: Tms::ObjCompStatuses.omitted_fields
              end
              transform Rename::Field, from: :objcompstatus, to: :origstatus
              transform Replace::FieldValueWithStaticMapping,
                source: :origstatus,
                target: :objcompstatus,
                mapping: Tms::ObjCompStatuses.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
