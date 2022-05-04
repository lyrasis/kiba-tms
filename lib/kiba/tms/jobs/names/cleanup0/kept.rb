# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module Kept
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :nameclean0__prep,
                  destination: :nameclean0__kept
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                transform Tms::Transforms::Names::Kept
              end
            end
          end
        end
      end
    end
  end
end
