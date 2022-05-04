# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Compiled0
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[locs__from_locations locs__from_obj_locs_temptext],
                destination: :locs__compiled_0
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
