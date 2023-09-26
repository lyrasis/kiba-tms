# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module FromLinkedSet
          module_function

          def job
            return unless Tms::LinkedSetAcq.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :linked_set_acq__prep,
                destination: :acquisitions__from_linked_set,
                lookup: :acquisitions__ids_final
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[registrationsetid objectstatus
                  acquisitionreferencenumber]
              transform Merge::ConstantValue,
                target: :objaccessiontreatment,
                value: "linkedset"
              transform Merge::MultiRowLookup,
                lookup: acquisitions__ids_final,
                keycolumn: :increment,
                fieldmap: {
                  acquisitionreferencenumber: :acquisitionreferencenumber
                }
            end
          end
        end
      end
    end
  end
end
