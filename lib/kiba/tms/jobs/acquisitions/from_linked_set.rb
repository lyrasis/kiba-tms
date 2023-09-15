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
                destination: :acquisitions__from_linked_set
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[registrationsetid objectstatus]
              transform Merge::ConstantValue,
                target: :objaccessiontreatment,
                value: "linkedset"
            end
          end
        end
      end
    end
  end
end
