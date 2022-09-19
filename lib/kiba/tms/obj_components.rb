# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjComponents
      extend Dry::Configurable
      module_function

      # The first three rows are fields all marked as not in use in the TMS data dictionary
      setting :delete_fields,
        default: %i[sortnumber injurisdiction],
        reader: true,
        constructor: ->value{ value << :conservationentityid unless Tms::ConservationEntities.used? }
      setting :empty_fields,
        default: {
          costmethodid: [nil, '', '0'],
          homecrateid: [nil, '', '0'],
          homelevel: [nil, '', '0'],
          prepcomments: [nil, '', '0'],
          readyexhibit: [nil, '', '0'],
          readystorage: [nil, '', '0'],
          receiveddate: [nil, '', '0'],
          searchhomecontainer: [nil, '', '0'],
          storageformatid: [nil, '', '0'],
          storagemethodid: [nil, '', '0'],
          tobecombined: [nil, '', '0'],
        },
        reader: true
      extend Tms::Mixins::Tableable

      # Whether or not ObjComponents is used to record information about actual object components
      #   (sub-objects). Either way TMS provides linkage to Locations through ObjComponents
      setting :actual_components, default: false, reader: true

      setting :inactive_mapping, default: {'0'=>'active', '1'=>'inactive'}, reader: true
      setting :text_entries_merge_xform, default: nil, reader: true
      setting :inventorystatus_fields, default: %i[objcompstatus active], reader: true
      setting :comment_fields, default: %i[storagecomments installcomments], reader: true

      setting :configurable, default: {
        actual_components: proc{ set_actual_components }
      },
        reader: true

      def set_actual_components
        Tms::Services::ObjComponents::ActualComponentDeterminer.call
      end

      def merging_text_entries?
        Tms::TextEntries.for?('ObjComponents') && text_entries_merge_xform
      end
    end
  end
end
