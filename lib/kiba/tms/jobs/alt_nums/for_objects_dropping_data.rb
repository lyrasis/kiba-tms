# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module ForObjectsDroppingData
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :alt_nums_reportable_for__objects_type_cleanup_merge,
                destination: :alt_nums__for_objects_dropping_data
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :treatment,
                value: "other_number"
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[remarks beginisodate endisodate]
              transform Delete::Fields,
                fields: %i[recordid sort treatment]
              transform Rename::Fields, fieldmap: {
                altnum: :other_number_value,
                targetrecord: :object_number,
                number_type: :orig_alt_number_type
              }
            end
          end
        end
      end
    end
  end
end
