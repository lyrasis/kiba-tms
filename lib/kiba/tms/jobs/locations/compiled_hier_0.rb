# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module CompiledHier0
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__compiled_0,
                destination: :locs__compiled_hier_0,
                lookup: :locs__compiled_0
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::Locations::EnsureHierarchy, lookup: locs__compiled_0
              transform Tms::Transforms::Locations::AddLocationType
            end
          end
        end
      end
    end
  end
end
