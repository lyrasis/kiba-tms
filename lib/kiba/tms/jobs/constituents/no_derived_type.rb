# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module NoDerivedType
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__without_type,
                destination: :constituents__no_derived_type
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject, field: :derivedcontype
            end
          end
        end
      end
    end
  end
end
