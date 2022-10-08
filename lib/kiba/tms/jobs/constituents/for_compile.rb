# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module ForCompile
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__constituents,
                destination: :constituents__for_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :namedata
              transform Delete::Fields,
                fields: %i[constituenttype derivedcontype inconsistent_org_names
                           defaultnameid defaultdisplaybioid namedata norm]
            end
          end
        end
      end
    end
  end
end
