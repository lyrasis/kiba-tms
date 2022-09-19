# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ActualComponents
          module_function

          def job
            return unless config.used?
            return unless config.actual_components
            
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
              transform FilterRows::FieldPopulated, action: :reject, field: :problemcomponent
              
              
              transform Delete::Fields,
                fields: %i[is_top_object problemcomponent existingobject duplicate
                           parentname parenttitle parentdesc]
              transform Rename::Fields, fieldmap: {
                parentobjectnumber: :parentobject,
                componentname: :title
              }
            end
          end
        end
      end
    end
  end
end
