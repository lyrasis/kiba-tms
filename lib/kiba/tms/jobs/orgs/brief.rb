# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Orgs
        module Brief
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :orgs__brief
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
                    row[:contype].start_with?("Org") &&
                    row[:relation_type] == "_main term"
                end
              transform Delete::FieldsExcept, fields: :name
              transform Rename::Field,
                from: :name,
                to: :termdisplayname
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :termdisplayname,
                target: :norm
              transform Deduplicate::Table,
                field: :norm,
                delete_field: false
            end
          end
        end
      end
    end
  end
end
