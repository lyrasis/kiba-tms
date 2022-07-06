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
              transform Delete::Fields, fields: %i[compstatforecolor compstatbackcolor available system systemid]
              transform Rename::Field, from: :objcompstatus, to: :origstatus
              transform Replace::FieldValueWithStaticMapping,
                source: :origstatus,
                target: :objcompstatus,
                mapping: Tms::ObjCompStatuses.inventory_status_mapping,
                fallback_val: 'NEEDS MAPPING',
                delete_source: false
            end
          end
        end
      end
    end
  end
end
