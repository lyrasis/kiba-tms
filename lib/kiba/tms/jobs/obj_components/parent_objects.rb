# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ParentObjects
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__with_object_numbers,
                destination: :obj_components__parent_objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :is_top_object
              transform Delete::Fields, fields: %i[is_top_object componentnumber]
            end
          end
        end
      end
    end
  end
end
