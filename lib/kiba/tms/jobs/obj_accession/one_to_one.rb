# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module OneToOne
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_accession,
                destination: :obj_accession__one_to_one
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::AnyFieldsPopulated,
                action: :reject,
                fields: %i[acquisitionlot acquisitionlotid registrationsetid]
            end
          end
        end
      end
    end
  end
end
