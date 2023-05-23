# frozen_string_literal: true

module Kiba
  module Tms
    module ObjComponents
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[sortnumber injurisdiction],
        reader: true
      extend Tms::Mixins::Tableable

      # Whether or not ObjComponents is used to record information about actual
      #   object components (sub-objects). Either way TMS table provides linkage
      #   to Locations through ObjComponents
      setting :actual_components, default: false, reader: true

      setting :inactive_mapping,
        default: {"0" => "active", "1" => "inactive"},
        reader: true
      setting :text_entries_merge_xform, default: nil, reader: true
      setting :inventorystatus_fields,
        default: %i[objcompstatus active],
        reader: true
      setting :comment_fields,
        default: %i[storagecomments installcomments],
        reader: true

      # Defines how auto-generated config settings are populated
      setting :configurable, default: {
                               actual_components: proc {
                                 Tms::Services::ObjComponents::ActualComponentDeterminer.call
                               }
                             },
        reader: true

      def merging_text_entries?
        Tms::TextEntries.for?("ObjComponents") && text_entries_merge_xform
      end
    end
  end
end
