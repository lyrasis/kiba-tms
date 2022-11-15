# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module TargetReport
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__media_files,
                destination: :media_files__target_report,
                lookup: :media_xrefs__for_target_report
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: media_xrefs__for_target_report,
                keycolumn: :rend_mediamasterid,
                fieldmap: {targettable: :tablename},
                delim: Tms.delim
            end
          end
        end
      end
    end
  end
end
