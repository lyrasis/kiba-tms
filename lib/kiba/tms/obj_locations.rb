# frozen_string_literal: true

module Kiba
  module Tms
    module ObjLocations
      extend Dry::Configurable

      module_function

      # Because they are conceptually about extracting location authority terms,
      #   a number of these settings are documented at:
      #   https://github.com/lyrasis/kiba-tms/blob/main/doc/mapping_options/locations.adoc

      setting :empty_fields,
        default: {
          dateout: [nil, "", "9999-12-31 00:00:00.000"],
          loclevel: [nil, "", "0"],
          tempticklerdate: [nil, "", "1900-01-01 00:00:00.000"]
        },
        reader: true
      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      setting :non_content_fields,
        default: %i[objlocationid componentid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[handler requestedby approver],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable

      # Since :inventorycontact and :movementcontact are single value fields
      #   in CS, which name should be set in these fields? First value (left
      #   to right) that is populated will be used.
      setting :contact_person_preference,
        default: %i[handler_person approver_person requestedby_person],
        reader: true

      # Array of transform classes to do default removal of otherwise
      #   migrating rows.
      # - DropScheduledComplete - removes "scheduled move to
      #   new home" or "scheduled temporary move" rows where transport_status
      #   is complete. Such a row is always followed by the movement to the
      #   scheduled place, which is the actual movement history we are
      #   interested in
      setting :default_droppers,
        default: [
          Tms::Transforms::ObjLocations::DropCancelled,
          Tms::Transforms::ObjLocations::DropScheduledComplete,
          Tms::Transforms::ObjLocations::DropScheduledPending
        ],
        reader: true

      # Array of transform classes to do project-specific removal of otherwise
      #   migrating rows
      setting :custom_droppers, default: [], reader: true

      # Settings related to creating LMIs and relating them to objects
      # Whether to drop rows marked inactive from the migration. The default
      #   is true because:
      # - TMS does not allow editing of this location data once it is entered
      # - Marking location data as inactive seems to be the way to indicate it
      #   was entered erroneously or accidentally
      # - There is no need to migrate bad data/mistakes to a new system
      setting :drop_inactive,
        default: true,
        reader: true

      # Initial/brief fingerprint fields. This fingerprint is merged in during
      #   Prep job. Later, in the Unique job, a full fingerprint is added
      setting :fingerprint_fields,
        default: [],
        reader: true,
        constructor: proc { |value|
          value << content_fields
          value.flatten!
          unless hier_lvl_lookup.empty?
            hier_lvl_lookup.each do |drop, add|
              value.delete(drop)
              value << add
            end
          end
          value.delete(:inactive) if drop_inactive
          value << :homelocationid
          value - %i[prevobjlocid nextobjlocid schedobjlocid]
        }

      # Fields included in full fingerprint value, which includes the initial
      #   fingerprint values for prev, next, and sched locs
      setting :full_fingerprint_fields,
        default: [],
        reader: true,
        constructor: proc { |value|
          value = [:fingerprint]
          value + %i[prevfp nextfp schedfp]
        }

      setting :inactive_treatment,
        default: :currentlocationnote,
        reader: true

      setting :inactive_note_string,
        default: "INACTIVE OBJECT LOCATION PROCEDURE",
        reader: true

      # client-specific mappings of TMS :location_purpose to CS
      # :reasonformove
      setting :reasonformove_remappings, default: {}, reader: true

      # client-specific transform to select only rows that should be treated as
      #   inventory LMIs
      setting :inventory_selector,
        default: Tms::Transforms::ObjLocations::InventorySelector,
        reader: true

      # client-specific transform to select only rows that should be treated as
      #   movement LMIs
      setting :movement_selector,
        default: Tms::Transforms::ObjLocations::MovementSelector,
        reader: true

      # client-specific transform to select only rows that should be treated as
      #   location-only LMIs
      setting :location_selector,
        default: Tms::Transforms::ObjLocations::LocationSelector,
        reader: true

      # Even out fields when compiling LMIs from inventory, location, and
      #   movement split jobs
      setting :lmi_field_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
        reader: true

      # @return [Integer] based on the number of rows in obj_locations__unique
      #   with no :year value (i.e. no :transdate value)
      setting :id_padding, default: 4, reader: true

      # Whether or not to create inventorynote and/or movementnote field
      #   values with labels appended to names in these fields. NOTE: the
      #   FIRST PERSON name from these fields is set as inventorycontact or
      #   movmementcontact, depending on how the row is treated. If there is
      #   only one name recorded, or the same name recorded for all rows, or
      #   the client does not care about retaining the roles, set to false
      setting :note_from_role_names, default: true, reader: true

      # Settings related to extracting Location authority terms
      setting :adds_sublocations,
        reader: true,
        constructor: ->(value) {
          return false unless temptext_mapping_done

          if fulllocid_fields.empty?
            false
          elsif fulllocid_fields_hier.intersect?(temptext_target_fields)
            true
          else
            false
          end
        }

      # @return [:hier, :nonhier] whether to use :fulllocid_fields or
      #   :fulllocid_fields_hier to build fulllocid value
      setting :fulllocid_mode, default: :hier, reader: true

      # @return [String] value appended to fulllocid when source field
      #   is blank
      setting :fulllocid_placeholder, default: "nil", reader: true

      # Which fields in obj_locations need to be concatenated with the location
      #   value to create additional location values (and thus need a unique id
      #   added to look them up)
      setting :fulllocid_fields,
        default: %i[loclevel searchcontainer shipmentnumber cratenumber
          sublevel],
        reader: true
      setting :loclevel_lvl,
        default: :loc3,
        reader: true
      setting :sublevel_lvl,
        default: :loc5,
        reader: true
      setting :searchcontainer_lvl,
        default: :loc8,
        reader: true
      setting :shipmentnumber_lvl,
        default: :loc11,
        reader: true
      setting :cratenumber_lvl,
        default: :loc12,
        reader: true
      setting :fulllocid_fields_hier,
        reader: true,
        constructor: proc {
          lkup = hier_lvl_lookup
          fulllocid_fields.map { |field| lkup.fetch(field, field) }
        }
      setting :temptext_mapping_done,
        default: false,
        reader: true
      # Client-specfic transform to run after merging completed temptext
      #   mappings into ObjLocations
      setting :temptext_mapping_post_xform,
        default: nil,
        reader: true
      # Lists temptext mappings used that indicate temptext value is part of
      #   location authority hierarchy. Used for post-mapping build of fullocid.
      #   Does not include note field mappings
      setting :temptext_target_fields,
        default: [],
        reader: true
      # Note field mappings for temptext
      setting :temptext_note_targets,
        default: [],
        reader: true
      setting :locnote_sources,
        default: [],
        reader: true

      def hier_lvl_lookup
        {
          loclevel: loclevel_lvl,
          searchcontainer: searchcontainer_lvl,
          sublevel: sublevel_lvl,
          shipmentnumber: shipmentnumber_lvl,
          cratenumber: cratenumber_lvl
        }.select { |key, _v| fulllocid_fields.any?(key) }
      end
    end
  end
end
