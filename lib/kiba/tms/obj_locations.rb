# frozen_string_literal: true

require 'dry-configurable'

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
          dateout: [nil, '', '9999-12-31 00:00:00.000'],
          tempticklerdate: [nil, '', '1900-01-01 00:00:00.000']
        },
        reader: true
      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[handler requestedby approver],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable

      # Settings related to creating LMIs and relating them to objects
      setting :drop_inactive,
        default: false,
        reader: true
      setting :inactive_note_string,
        default: 'INACTIVE OBJECT LOCATION PROCEDURE',
        reader: true
      setting :inactive_treatment,
        default: :inventorynote,
        reader: true
      setting :temptext_note_targets,
        default: [],
        reader: true

      # Settings related to extracting Location authority terms
      setting :adds_sublocations,
        reader: true,
        constructor: ->(value){
          return false unless temptext_mapping_done

          if fulllocid_fields.empty?
            false
          elsif fulllocid_fields_hier.intersect?(temptext_target_fields)
            true
          else
            false
          end
        }
      setting :cratenumber_lvl,
        default: :loc12,
        reader: true
      # Which fields in obj_locations need to be concatenated with the location
      #   value to create additional location values (and thus need a unique id
      #   added to look them up)
      setting :fulllocid_fields,
        default: %i[loclevel searchcontainer shipmentnumber cratenumber
                    sublevel],
        reader: true
      setting :fulllocid_fields_hier,
        reader: true,
        constructor: proc{
          lkup = hier_lvl_lookup
          fulllocid_fields.map{ |field| lkup[field] }
        }
      setting :searchcontainer_lvl,
        default: :loc8,
        reader: true
      setting :shipmentnumber_lvl,
        default: :loc11,
        reader: true
      setting :sublevel_lvl,
        default: :loc9,
        reader: true
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

      def hier_lvl_lookup
        {
          loclevel: :loc6,
          searchcontainer: searchcontainer_lvl,
          sublevel: sublevel_lvl,
          shipmentnumber: shipmentnumber_lvl,
          cratenumber: cratenumber_lvl
        }.select{ |key, _v| fulllocid_fields.any?(key) }
      end
    end
  end
end
