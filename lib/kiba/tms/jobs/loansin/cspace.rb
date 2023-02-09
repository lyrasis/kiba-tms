# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansin
        module Cspace
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loansin__prep,
                destination: :loansin__cspace
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :loanid
              transform Delete::EmptyFields
            end
          end
        end
      end
    end
  end
end
