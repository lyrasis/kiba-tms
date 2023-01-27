# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module Flagged
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :persons__cspace,
                destination: :persons__flagged
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::FlagAll,
                on_field: :namemergenorm,
                in_field: :duplicates
              transform Deduplicate::Flag,
                on_field: :namemergenorm,
                in_field: :drop_from_mig,
                using: {}
            end
          end
        end
      end
    end
  end
end
