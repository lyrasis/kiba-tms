# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup0
          module PersonsDuplicates
            module_function

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: :nameclean0__persons_kept,
                  destination: :nameclean0__persons_duplicates
                },
                transformer: xforms
              )
            end

            def xforms
              Kiba.job_segment do
                @deduper = {}
                transform Deduplicate::Flag, on_field: :norm, in_field: :duplicate, using: @deduper, explicit_no: false
                transform FilterRows::FieldPopulated, action: :keep, field: :duplicate
              end
            end
          end
        end
      end
    end
  end
end
