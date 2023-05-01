# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module ForObjReportPrep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :alt_nums__merge_occs,
                destination: :alt_nums__for_obj_report_prep
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[description remarks],
                target: :combined,
                sep: " - ",
                delete_sources: false
            end
          end
        end
      end
    end
  end
end
