# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module NoFilename
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__target_report,
                destination: :media_files__no_filename
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :filename
              transform Merge::ConstantValue,
                target: :unmigratable_reason,
                value: "no filename"
            end
          end
        end
      end
    end
  end
end
