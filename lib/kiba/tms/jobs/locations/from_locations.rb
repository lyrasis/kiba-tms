# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module FromLocations
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__locations,
                destination: :locs__from_locations
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[locationid location_name parent_location
                  storage_location_authority locationtype address]
              transform Tms::Transforms::ObjLocations::AddFulllocid
              transform Delete::Fields, fields: :locationid
              transform Merge::ConstantValue,
                target: :term_source,
                value: "Locations"
            end
          end
        end
      end
    end
  end
end
