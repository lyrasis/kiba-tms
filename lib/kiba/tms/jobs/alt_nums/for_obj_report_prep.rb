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
                source: :prep__alt_nums,
                destination: :alt_nums__for_obj_report_prep
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

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
