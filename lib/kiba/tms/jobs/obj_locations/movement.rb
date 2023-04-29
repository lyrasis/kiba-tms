# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Movement
          module_function

          def job
            return if config.movement_selector.nil?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :obj_locations__unique,
                destination: :obj_locations__movement
              },
              transformer: xforms,
              helper: config.lmi_field_normalizer
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform config.movement_selector

              transform Tms::Transforms::IdGenerator,
                prefix: "MV",
                id_source: :year,
                id_target: :movementreferencenumber,
                sort_on: :objlocationid,
                sort_type: :i,
                omit_suffix_if_single: false,
                padding: 4

              transform Tms::Transforms::ObjLocations::MergeHomeLocIntoCurrentTemp

              transform Rename::Fields, fieldmap: {
                transdate: :locationdate,
                location_purpose: :reasonformove,
                dateout: :removaldate,
                anticipenddate: :plannedremovaldate
              }

              transform Tms::Transforms::ObjLocations::AssignContactPerson,
                target: :movement

              transform Tms::Transforms::ObjLocations::RoleFieldNotes,
                target: :movement
            end
          end
        end
      end
    end
  end
end
