# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConXrefDetails
        module ForRegistrationSets
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_xref_details,
                destination: :con_xref_details__for_registration_sets
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep,
                field: :tablename, value: "RegistrationSets"
              transform Delete::Fields, fields: :tablename
            end
          end
        end
      end
    end
  end
end
