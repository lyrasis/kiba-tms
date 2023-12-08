# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDates
        module AllUniq
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.all_sources,
                destination: :obj_dates__all_uniq
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :date_value
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :date_value
            end
          end
        end
      end
    end
  end
end
