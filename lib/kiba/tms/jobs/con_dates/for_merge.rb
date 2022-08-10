# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module ForMerge
          module_function

          def job
            return unless Tms::Table::List.include?('ConDates')
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_dates,
                destination: :con_dates__for_merge
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do

            end
          end
        end
      end
    end
  end
end
