# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module FileNames
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__media_files,
                destination: :media_files__file_names
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: %i[path filename]
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :filename
            end
          end
        end
      end
    end
  end
end
