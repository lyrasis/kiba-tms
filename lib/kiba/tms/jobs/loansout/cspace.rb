# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansout
        module Cspace
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loansout__prep,
                destination: :loansout__cspace
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :loanid
            end
          end
        end
      end
    end
  end
end
