# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConEMail
        module Dropping
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_email,
                destination: :con_email__dropping
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :reject,
                field: :keeping, value: "y"
            end
          end
        end
      end
    end
  end
end
