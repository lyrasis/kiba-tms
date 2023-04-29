# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module PersonsNotKeptMissingTarget
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :nameclean0__persons_not_kept,
                  destination: :nameclean0__persons_not_kept_missing_target
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                transform FilterRows::FieldPopulated, action: :reject,
                  field: :keptname
              end
            end
          end
        end
      end
    end
  end
end
