# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module Duplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__for_compile,
                destination: :constituents__duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :duplicate
              transform Delete::Fields, fields: :duplicate

              if Tms.migration_status == :dev
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: Tms::Constituents.preferred_name_field,
                  value: Tms::NameTypeCleanup.dropped_name_indicator
              end

              transform Sort::ByFieldValue, field: :combined
            end
          end
        end
      end
    end
  end
end
