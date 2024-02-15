# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module DateUniq
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__date_base,
                destination: :reference_master__date_uniq
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :displaydate
              transform Rename::Field,
                from: :displaydate,
                to: :date_value
              transform Delete::FieldsExcept,
                fields: :date_value
            end
          end
        end
      end
    end
  end
end
