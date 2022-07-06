# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module Objects
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__actual_components,
                destination: :obj_components__objects
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[componentnumber objcompstatus active physdesc storagecomments installcomments
                           compcount title]
              transform Rename::Fields, fieldmap: {
                componentnumber: :objectnumber,
                physdesc: :briefdescription,
                compcount: :numberofobjects
              }
              transform Merge::ConstantValue, target: :cataloglevel, value: 'component'
              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::ObjComponents.inventorystatus_fields,
                target: :inventorystatus,
                sep: Tms.delim,
                delete_sources: true
              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::ObjComponents.comment_fields,
                target: :comment,
                sep: Tms.delim,
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
