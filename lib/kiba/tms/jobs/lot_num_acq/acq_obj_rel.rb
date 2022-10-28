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
                destination: :lot_num_acq__acq_obj_rel
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber acquisitionlot]
              transform Rename::Fields, fieldmap: {
                acquisitionlot: :item1_id,
                objectnumber: :item2_id
              }
              transform Merge::ConstantValues, constantmap: {
                item1_type: 'acquisitions',
                item2_type: 'collectionobjects'
              }
            end
          end
        end
      end
    end
  end
end
