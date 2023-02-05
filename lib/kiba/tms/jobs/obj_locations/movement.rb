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
                destination: :obj_locations__movement,
                lookup: :obj_components__current_loc_lookup
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
                prefix: 'MV',
                id_source: :year,
                id_target: :movementreferencenumber,
                sort_on: :objlocationid,
                sort_type: :i,
                omit_suffix_if_single: false,
                padding: 4

              transform Merge::MultiRowLookup,
                lookup: obj_components__current_loc_lookup,
                keycolumn: :fullfingerprint,
                fieldmap: {fp: :fullfingerprint},
                constantmap: {current: 'y'}
              transform Delete::FieldsExcept,
                fields: %i[objectnumber is_temp transdate location_purpose
                           transport_type transport_status
                           homelocationname handler requestedby approver
                           dateout anticipenddate currentlocationnote
                           prev_location next_location sched_location
                           currentlocationlocationlocal
                           currentlocationlocationoffsite
                           currentlocationorganizationlocal
                           normallocationlocationlocal
                           normallocationlocationoffsite
                           normallocationorganizationlocal
                           movementreferencenumber]

              transform do |row|
                tmp = row[:is_temp]
                next row if tmp == 'y'

                row[:homelocationname] = nil
                row[:homelocationauth] = nil
                row
              end

              transform Tms::Transforms::ObjLocations::LocToColumns,
                locsrc: :homelocationname,
                authsrc: :homelocationauth,
                target: 'normallocation'
              transform Rename::Fields, fieldmap: {
                transdate: :locationdate,
                location_purpose: :reasonformove,
                handler: :inventorycontact,
                dateout: :removaldate,
                anticipenddate: :plannedremovaldate
              }
            end
          end
        end
      end
    end
  end
end
