# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LinkedSetAcq
        module Rows
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_accession,
                destination: :linked_set_acq__rows
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[acquisitionlotid registrationsetid]
            end
          end
        end
      end
    end
  end
end
