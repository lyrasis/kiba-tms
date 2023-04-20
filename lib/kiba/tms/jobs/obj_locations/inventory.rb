# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Inventory
          module_function

          def job
            return if config.inventory_selector.nil?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :obj_locations__unique,
                destination: :obj_locations__inventory
              },
              transformer: xforms,
              helper: config.lmi_field_normalizer
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform config.inventory_selector

              transform Tms::Transforms::IdGenerator,
                prefix: 'INV',
                id_source: :year,
                id_target: :movementreferencenumber,
                sort_on: :objlocationid,
                sort_type: :i,
                omit_suffix_if_single: false,
                padding: 4

              transform Rename::Fields, fieldmap: {
                transdate: :locationdate,
                location_purpose: :reasonformove
              }
              transform Copy::Field,
                from: :locationdate,
                to: :inventorydate

              transform Tms::Transforms::ObjLocations::AssignContactPerson,
                target: :inventory
              transform Tms::Transforms::ObjLocations::RoleFieldNotes,
                target: :inventory
            end
          end
        end
      end
    end
  end
end
