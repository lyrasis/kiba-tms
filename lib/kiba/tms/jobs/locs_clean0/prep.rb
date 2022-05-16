# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean0
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__cleaned0,
                destination: :locclean0__prep
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :usage_ct
            end
          end
        end
      end
    end
  end
end
