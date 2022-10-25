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
              transformer: Tms::LinkedSetAcq.select_xform
            )
          end
        end
      end
    end
  end
end
