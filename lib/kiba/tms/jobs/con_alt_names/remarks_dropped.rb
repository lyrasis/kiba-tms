# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConAltNames
        module RemarksDropped
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_alt_names__prep_clean,
                destination: :con_alt_names__remarks_dropped
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :remarks
              transform Delete::FieldsExcept,
                fields: %i[conname altname conauthtype remarks]
              transform Rename::Fields, fieldmap: {
                conname: :name,
                conauthtype: :name_type
              }
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
