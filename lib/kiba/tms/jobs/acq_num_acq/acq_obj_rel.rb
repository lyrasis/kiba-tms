# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AcqNumAcq
        module AcqObjRel
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acq_num_acq__combined,
                destination: :acq_num_acq__acq_obj_rel,
                lookup: %i[acq_num_acq__rows
                  acquisitions__ids_final]
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber combined]
              transform Merge::MultiRowLookup,
                lookup: acq_num_acq__rows,
                keycolumn: :combined,
                fieldmap: {increment: :increment}
              transform Merge::MultiRowLookup,
                lookup: acquisitions__ids_final,
                keycolumn: :increment,
                fieldmap: {item1_id: :acquisitionreferencenumber}
              transform Delete::Fields,
                fields: %i[combined refnum increment]
              transform Rename::Field,
                from: :objectnumber,
                to: :item2_id
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
