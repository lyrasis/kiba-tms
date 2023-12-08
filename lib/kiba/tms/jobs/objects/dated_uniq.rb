# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module DatedUniq
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__date_prep,
                destination: :objects__dated_uniq
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :dated
              transform Deduplicate::Table,
                field: :dated
              transform Rename::Field,
                from: :dated,
                to: :date_value
            end
          end
        end
      end
    end
  end
end
