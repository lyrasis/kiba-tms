# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConPhones
        module Dropping
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_phones,
                destination: :con_phones__dropping
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :reject, field: :keeping, value: "y"
            end
          end
        end
      end
    end
  end
end
