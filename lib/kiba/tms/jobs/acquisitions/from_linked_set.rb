# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module FromLinkedSet
          module_function

          def job
            return unless Tms::LinkedSetAcq.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :linked_set_acq__prep,
                destination: :acquisitions__from_linked_set
              },
              transformer: xforms,
              helper: config.multisource_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[registrationsetid objectstatus]
            end
          end
        end
      end
    end
  end
end
