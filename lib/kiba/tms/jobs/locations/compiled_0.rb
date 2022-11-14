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
                source: sources,
                destination: :locs__compiled_0
              },
              transformer: xforms
            )
          end

          def sources
            base = [:locs__from_locations]
            base << :locs__from_obj_locs if Tms::ObjLocations.adds_sublocations
            base
          end

          def xforms
            Kiba.job_segment do
              transform Append::NilFields,
                fields: Tms::Locations.multi_source_normalizer.get_fields
            end
          end
        end
      end
    end
  end
end
