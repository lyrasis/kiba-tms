# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ActualComponents
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__with_object_numbers,
                destination: :obj_components__actual_components
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject, field: :is_top_object
              transform Delete::Fields, fields: :is_top_object
              transform Rename::Fields, fieldmap: {
                objectnumber: :parentobject,
                componentname: :title
              }
            end
          end
        end
      end
    end
  end
end
