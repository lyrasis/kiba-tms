# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module AcqNumber
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_accession,
                destination: :obj_accession__acq_number
              },
              transformer: Tms::AcqNumAcq.select_xform
            )
          end
        end
      end
    end
  end
end
