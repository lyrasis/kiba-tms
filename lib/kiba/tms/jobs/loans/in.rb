# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loans
        module In
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__loans,
                destination: :loans__in
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :loantype,
                value: "loan in"
              transform Delete::Fields, fields: :loantype
            end
          end
        end
      end
    end
  end
end
