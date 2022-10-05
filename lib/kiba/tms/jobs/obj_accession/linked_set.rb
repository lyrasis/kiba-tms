# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module LinkedSet
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_accession,
                destination: :obj_accession__linked_set
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[registrationsetid acquisitionlotid]
            end
          end
        end
      end
    end
  end
end
