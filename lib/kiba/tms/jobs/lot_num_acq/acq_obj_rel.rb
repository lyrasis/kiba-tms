# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LotNumAcq
        module AcqObjRel
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :lot_num_acq__obj_rows,
                destination: :lot_num_acq__acq_obj_rel,
                lookup: %i[lot_num_acq__prep
                  acquisitions__ids_final]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber acquisitionlot]
              transform Merge::MultiRowLookup,
                lookup: lot_num_acq__prep,
                keycolumn: :acquisitionlot,
                fieldmap: {increment: :increment}
              transform Merge::MultiRowLookup,
                lookup: acquisitions__ids_final,
                keycolumn: :increment,
                fieldmap: {item1_id: :acquisitionreferencenumber}
              transform Delete::Fields,
                fields: %i[acquisitionlot increment]

              transform Rename::Fields, fieldmap: {
                objectnumber: :item2_id
              }
              transform Merge::ConstantValues, constantmap: {
                item1_type: "acquisitions",
                item2_type: "collectionobjects"
              }
            end
          end
        end
      end
    end
  end
end
