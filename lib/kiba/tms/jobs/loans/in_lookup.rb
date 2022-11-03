# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loans
        module InLookup
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loans,
                destination: :loans__in_lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :loanin,
                value: '1'
              transform Delete::FieldsExcept,
                fields: :loanid
            end
          end
        end
      end
    end
  end
end
