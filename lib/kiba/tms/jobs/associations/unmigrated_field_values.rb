# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Associations
        module UnmigratedFieldValues
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :associations__in_migration,
                destination: :associations__unmigrated_field_values
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Append::NilFields,
                fields: %i[keep]

              # flag rows to keep
              transform do |row|
                table = row[:tablename]
                next row unless table == "Constituents"

                vals = %i[remarks displaydate datebegin dateend].map { |field|
                  row[field]
                }.reject(&:blank?)
                next row if vals.empty?

                row[:keep] = "y"
                row
              end

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :keep
              transform Delete::Fields,
                fields: %i[associationid id1 id2 keep]
            end
          end
        end
      end
    end
  end
end
