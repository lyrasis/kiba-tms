# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loans
        module Out
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__loans,
                destination: :loans__out
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :loantype,
                value: "loan out"
              transform Delete::Fields, fields: :loantype
            end
          end
        end
      end
    end
  end
end
