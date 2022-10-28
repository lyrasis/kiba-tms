# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LinkedSetAcq
        module AcqObjRel
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :linked_set_acq__obj_rows,
                destination: :linked_set_acq__acq_obj_rel,
                lookup: :linked_set_acq__prep
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[objectnumber registrationsetid]
              transform Merge::MultiRowLookup,
                lookup: linked_set_acq__prep,
                keycolumn: :registrationsetid,
                fieldmap: {item1_id: :acquisitionreferencenumber}
              transform Rename::Field,
                from: :objectnumber,
                to: :item2_id
              transform Merge::ConstantValues, constantmap: {
                item1_type: 'acquisitions',
                item2_type: 'collectionobjects'
              }
              transform Delete::Fields,
                fields: :registrationsetid
            end
          end
        end
      end
    end
  end
end
