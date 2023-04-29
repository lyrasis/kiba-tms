# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module DroppingNoLocation
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__location_names_merged,
                destination: :obj_locations__dropping_no_location
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :location
              transform Merge::ConstantValue,
                target: :dropreason,
                value: "No location value"
            end
          end
        end
      end
    end
  end
end
