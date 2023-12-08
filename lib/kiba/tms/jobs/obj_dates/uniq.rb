# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDates
        module Uniq
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_dates,
                destination: :obj_dates__uniq
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :datetext
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :datetext
              transform Deduplicate::Table,
                field: :datetext
              transform Rename::Field,
                from: :datetext,
                to: :date_value
            end
          end
        end
      end
    end
  end
end
