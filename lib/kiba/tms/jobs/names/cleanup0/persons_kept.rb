# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module PersonsKept
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :nameclean0__kept,
                  destination: :nameclean0__persons_kept
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                transform FilterRows::FieldEqualTo, action: :keep,
                  field: :constituenttype, value: "Person"
              end
            end
          end
        end
      end
    end
  end
end
