# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module ForTargetReport
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__media_xrefs,
                destination: :media_xrefs__for_target_report
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[mediamasterid tablename]
            end
          end
        end
      end
    end
  end
end
