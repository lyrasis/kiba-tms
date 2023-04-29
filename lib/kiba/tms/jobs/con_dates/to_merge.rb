# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConDates
        module ToMerge
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_dates__prep_compiled,
                destination: :con_dates__to_merge
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[datasource warn datedescription date remarks]
            end
          end
        end
      end
    end
  end
end
