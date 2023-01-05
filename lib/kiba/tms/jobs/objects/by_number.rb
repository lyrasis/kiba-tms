# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module ByNumber
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__numbers_cleaned,
                destination: :objects__by_number
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
