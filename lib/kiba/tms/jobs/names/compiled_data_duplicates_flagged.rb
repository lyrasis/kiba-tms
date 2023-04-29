# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module CompiledDataDuplicatesFlagged
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[names__initial_compile],
                destination: :names__flagged_duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :duplicate
              transform Deduplicate::Table, field: :norm, delete_field: false
              transform Delete::FieldsExcept, fields: :norm
              transform Merge::ConstantValue, target: :duplicate, value: "y"
            end
          end
        end
      end
    end
  end
end
