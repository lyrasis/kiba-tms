# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module NhrLmiObj
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__lmi,
                destination: :obj_locations__nhr_lmi_obj
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[movementreferencenumber objectnumber]
              transform Explode::RowsFromMultivalField,
                field: :objectnumber,
                delim: Tms.delim
              transform Rename::Fields, fieldmap: {
                objectnumber: :item1_id,
                movementreferencenumber: :item2_id
              }
              transform Merge::ConstantValues,
                constantmap: {
                  item1_type: "collectionobjects",
                  item2_type: "movements"
                }
              transform CombineValues::FullRecord, target: :index
              transform Deduplicate::Table,
                field: :index,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
