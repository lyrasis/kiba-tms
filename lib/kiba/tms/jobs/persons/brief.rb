# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module Brief
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :persons__brief
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  row[:contype] &&
                    row[:contype].start_with?('Person') &&
                    row[:relation_type] == '_main term'
                end
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :name,
                value: 'DROPPED FROM MIGRATION'
              transform Delete::FieldsExcept, fields: :name
              transform Rename::Field,
                from: :name,
                to: :termdisplayname
            end
          end
        end
      end
    end
  end
end
