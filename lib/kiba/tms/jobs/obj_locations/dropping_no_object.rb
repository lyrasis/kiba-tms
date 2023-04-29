# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module DroppingNoObject
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__location_names_merged,
                destination: :obj_locations__dropping_no_object
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :objectnumber
              transform Merge::ConstantValue,
                target: :dropreason,
                value: "No linked object"
            end
          end
        end
      end
    end
  end
end
