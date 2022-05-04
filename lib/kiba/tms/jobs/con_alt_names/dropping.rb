# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAltNames
        module Dropping
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_alt_names__only_alt,
                destination: :con_alt_names__dropping
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :reject, field: :kept, value: 'y'
            end
          end
        end
      end
    end
  end
end

