# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OneToOneAcq
        module AcqObjRel
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :one_to_one_acq__obj_rows,
                destination: :one_to_one_acq__acq_obj_rel
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber]
              transform Rename::Fields, fieldmap: {
                objectnumber: :item2_id
              }
              transform Copy::Field,
                from: :item2_id,
                to: :item1_id
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
