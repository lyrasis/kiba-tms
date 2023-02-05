# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Location
          module_function

          def job
            return if config.location_selector.nil?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :obj_locations__unique,
                destination: :obj_locations__location
              },
              transformer: xforms,
              helper: config.lmi_field_normalizer
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform config.location_selector

              transform Tms::Transforms::IdGenerator,
                prefix: 'LOC',
                id_source: :year,
                id_target: :movementreferencenumber,
                sort_on: :objlocationid,
                sort_type: :i,
                omit_suffix_if_single: false,
                padding: 4

              transform Delete::FieldsExcept,
                fields: %i[objectnumber transdate location_purpose
                           transport_statuslocation handler
                           currentlocationnote
                           currentlocationlocationlocal
                           currentlocationlocationoffsite
                           currentlocationorganizationlocal
                           movementreferencenumber]
              transform Rename::Fields, fieldmap: {
                transdate: :locationdate,
                location_purpose: :reasonformove,
                handler: :inventorycontact
              }
            end
          end
        end
      end
    end
  end
end
