# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansin
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loans__in,
                destination: :loansin__prep
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
            end
          end
        end
      end
    end
  end
end
