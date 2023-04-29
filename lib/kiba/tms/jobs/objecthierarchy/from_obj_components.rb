# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objecthierarchy
        module FromObjComponents
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__actual_components,
                destination: :objecthierarchy__from_obj_components
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[componentnumber parentobject component_type]
              transform Rename::Fields, fieldmap: {
                componentnumber: :narrower_object_number,
                parentobject: :broader_object_number,
                component_type: :relationship_type
              }
            end
          end
        end
      end
    end
  end
end
