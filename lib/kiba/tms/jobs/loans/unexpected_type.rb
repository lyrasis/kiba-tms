# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loans
        module UnexpectedType
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__loans,
                destination: :loans__unexpected_type
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :reject,
                field: :loantype, value: "loan out"
              transform FilterRows::FieldEqualTo, action: :reject,
                field: :loantype, value: "loan in"
            end
          end
        end
      end
    end
  end
end
