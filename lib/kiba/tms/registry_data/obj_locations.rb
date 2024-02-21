# frozen_string_literal: true

module Kiba
  module Tms
    module RegistryData
      module ObjLocations
        module_function

        def register
          Kiba::Tms.registry.namespace("movement") do
            register :ingest_hist, {
              creator: Kiba::Tms::Jobs::Movement::IngestHist,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "movement_hist.csv"),
              tags: %i[obj_locations lmi movement],
              desc: "Non-current LMIs. Should be loaded and related to "\
                "objects before current LMIs are"
            }
            register :nhr_hist, {
              creator: Kiba::Tms::Jobs::Movement::NhrHist,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "nhr_movement_object_hist.csv"),
              tags: %i[obj_locations lmi movement nhrs],
              desc: "Non-current LMIs. Should be loaded and related to "\
                "objects before current LMIs are"
            }
            register :ingest_current, {
              creator: Kiba::Tms::Jobs::Movement::IngestCurrent,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "movement_current.csv"),
              tags: %i[obj_locations lmi movement],
              desc: "Current LMIs. Should be loaded and related to "\
                "objects after non-current LMIs are"
            }
            register :nhr_current, {
              creator: Kiba::Tms::Jobs::Movement::NhrCurrent,
              path: File.join(Kiba::Tms.datadir, "ingest",
                "nhr_movement_object_current.csv"),
              tags: %i[obj_locations lmi movement nhrs],
              desc: "Non-current LMIs. Should be loaded and related to "\
                "objects before current LMIs are"
            }
          end

          Kiba::Tms.registry.namespace("obj_locations") do
            register :migrating, {
              creator: Kiba::Tms::Jobs::ObjLocations::Migrating,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_migrating.csv"),
              tags: %i[obj_locations],
              desc: "- Removes rows where :objlocationid = -1\n"\
                "- Removes rows where :locationid = -1\n"\
                "- If migration is configured to drop inactive "\
                "rows, drops rows where :inactive = 1"\
                "- Adds fullfingerprint",
              dest_special_opts: {
                initial_headers:
                %i[objectnumber objlocationid is_temp transdate
                  location_purpose transport_type transport_status
                  location prevobjlocid nextobjlocid]
              },
              lookup_on: :objlocationid
            }
            register :migrating_custom, {
              creator: Kiba::Tms::Jobs::ObjLocations::MigratingCustom,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_migrating_custom.csv"),
              tags: %i[obj_locations],
              desc: "- Removes project-specific omission rows",
              lookup_on: :objlocationid
            }
            register :unique, {
              creator: Kiba::Tms::Jobs::ObjLocations::Unique,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_unique.csv"),
              tags: %i[obj_locations],
              desc: "- Deduplicates on :fullfingerprint\n"\
                "- Merge in related objectnumbers\n"\
                "- Merge in :homelocationname\n"\
                "- Add :year field (for use building movementrefnums)\n"\
                "- Merge names",
              dest_special_opts: {
                initial_headers:
                %i[objectnumber objlocationid is_temp transdate
                  location_purpose transport_type transport_status
                  location homelocationname prevobjlocid nextobjlocid]
              }
            }
            register :inventory, {
              creator: Kiba::Tms::Jobs::ObjLocations::Inventory,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_inventory.csv"),
              tags: %i[obj_locations],
              desc: "Filter to only rows treated as Inventory LMI"
            }
            register :lmi, {
              creator: Kiba::Tms::Jobs::ObjLocations::Lmi,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_lmi.csv"),
              tags: %i[obj_locations],
              desc: "Compile inventory, location, and movement LMIs",
              dest_special_opts: {initial_headers: %i[movementreferencenumber]}
            }
            register :lmi_exploded, {
              creator: Kiba::Tms::Jobs::ObjLocations::LmiExploded,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_lmi_exploded.csv"),
              tags: %i[obj_locations],
              desc: ":obj_locations__lmi exploded to one row per object "\
                "number. Used in reporting/data review",
              dest_special_opts: {
                initial_headers: %i[objectnumber movementreferencenumber]
              }
            }
            register :location, {
              creator: Kiba::Tms::Jobs::ObjLocations::Location,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_location.csv"),
              tags: %i[obj_locations],
              desc: "Filter to only rows treated as Location LMI"
            }
            register :movement, {
              creator: Kiba::Tms::Jobs::ObjLocations::Movement,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_movement.csv"),
              tags: %i[obj_locations],
              desc: "Filter to only rows treated as Movement LMI"
            }
            register :inactive_review, {
              creator: Kiba::Tms::Jobs::ObjLocations::InactiveReview,
              path: File.join(Kiba::Tms.datadir, "reports",
                "obj_locations_inactive_review.csv"),
              tags: %i[obj_locations reports],
              dest_special_opts: {
                initial_headers:
                %i[objectnumber objlocationid inactive transdate dateout
                  location movementnote is_temp
                  location_purpose transport_type transport_status
                  sched_location prev_location next_location]
              }
            }
            register :dropping, {
              creator: Kiba::Tms::Jobs::ObjLocations::Dropping,
              path: File.join(Kiba::Tms.datadir, "reports",
                "obj_locations_dropping_from_migration.csv"),
              tags: %i[obj_locations reports],
              desc: "ObjLocation rows to be omitted from the migration. "\
                "The reason for omission is stated in the :dropreason column. "\
                "LMIs in CS that are not attached to any Object record(s) do "\
                "not serve any purpose. LMIs in CS require a location value, "\
                "so if there is not an associated location, we cannot create "\
                "and LMI in the migration",
              dest_special_opts: {
                initial_headers:
                %i[objlocationid dropreason objectnumber transdate location]
              }

            }
            register :dropping_no_location, {
              creator: Kiba::Tms::Jobs::ObjLocations::DroppingNoLocation,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_dropping_no_location.csv"),
              tags: %i[obj_locations],
              desc: "ObjLocation rows with no linked Storage Location value. "\
                "Adds :dropreason column"
            }
            register :dropping_no_object, {
              creator: Kiba::Tms::Jobs::ObjLocations::DroppingNoObject,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_dropping_no_object.csv"),
              tags: %i[obj_locations],
              desc: "ObjLocation rows having no linked Object value. "\
                "Adds :dropreason column"
            }
            register :location_names_merged, {
              creator: Kiba::Tms::Jobs::ObjLocations::LocationNamesMerged,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_location_names_merged.csv"),
              tags: %i[obj_locations],
              desc: "Merges location names (using fulllocid) into location, "\
                "prevloc, nextloc, and scheduled loc fields",
              lookup_on: :objectnumber
            }
            register :mappable_temptext, {
              creator: Kiba::Tms::Jobs::ObjLocations::MappableTemptext,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "obj_location_temptext_for_mapping.csv"
              ),
              tags: %i[obj_locations locs cleanup],
              desc: "Unique tmslocationstring + temptext values for client to "\
                "categorize/map into sublocations or notes",
              dest_special_opts: {
                initial_headers: %i[temptext mapping corrected_value
                  loc1 loc3 loc5
                  objectnumber transdate dateout]
              }
            }
            register :mappable_temptext_support, {
              creator: Kiba::Tms::Jobs::ObjLocations::MappableTemptextSupport,
              path: File.join(
                Kiba::Tms.datadir,
                "reports",
                "objlocations_reference_for_temptext_mapping.csv"
              ),
              tags: %i[obj_locations locs],
              desc: "ObjLocations rows with temptext values, with "\
                "tmslocationstring values merged in. Provided to client to "\
                "support completing mappable_temptext worksheet",
              dest_special_opts: {
                initial_headers: %i[temptext loc1 loc3 loc5
                  objectnumber transdate dateout]
              }
            }
            if Tms::ObjLocations.temptext_mapping_done
              register :temptext_mapped, {
                path: File.join(
                  Kiba::Tms.datadir,
                  "supplied",
                  "obj_locations_temptext_for_mapping.csv"
                ),
                tags: %i[obj_locations locs],
                supplied: true
              }
              register :temptext_mapped_for_merge, {
                creator: Tms::Jobs::ObjLocations::TemptextMappedForMerge,
                path: File.join(
                  Kiba::Tms.datadir,
                  "working",
                  "obj_locations_temptext_mapped_for_merge.csv"
                ),
                tags: %i[obj_locations locs],
                desc: "Removes unneeded fields; adds :lookup column",
                lookup_on: :lookup
              }
            end
            register :fulllocid_lookup, {
              creator: Kiba::Tms::Jobs::ObjLocations::FulllocidLookup,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_by_fulllocid.csv"),
              tags: %i[obj_locations],
              desc: "Deletes everything else. Used to get counts of location "\
                "usages",
              lookup_on: :fulllocid
            }
            register :prev_next_sched_loc_merge, {
              creator: Kiba::Tms::Jobs::ObjLocations::PrevNextSchedLocMerge,
              path: File.join(Kiba::Tms.datadir, "working",
                "obj_locations_prev_next_sched_merged.csv"),
              tags: %i[obj_locations obj_components reports]
            }
          end
        end
      end
    end
  end
end
