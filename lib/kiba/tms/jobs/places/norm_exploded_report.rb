# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module NormExplodedReport
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__norm_exploded_report_prep,
                destination: :places__norm_exploded_report
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              if Tms.final_data_cleaner
                transform Tms.final_data_cleaner,
                  fields: %i[value key left_combined objectnumbers objecttitles
                             objectdescriptions]
              end
            end
          end
        end
      end
    end
  end
end
