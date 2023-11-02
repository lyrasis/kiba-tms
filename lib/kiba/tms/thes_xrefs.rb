# frozen_string_literal: true

module Kiba
  module Tms
    module ThesXrefs
      extend Dry::Configurable

      module_function

      # As with ObjLocations, it appears that inactive here is a way to mark
      #   erroneous/accidental entries
      setting :drop_inactive, default: true, reader: true

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[removedloginid removeddate],
        reader: true
      extend Tms::Mixins::Tableable

      setting :type_field, default: :thesxreftype, reader: true
      setting :mergeable_value_field, default: :termused, reader: true
      setting :additional_occurrence_ct_fields,
        default: %i[remarks],
        reader: true
      extend Tms::Mixins::MultiTableMergeable

      # Mappings for :thesxreftableid field values. Listed in data dictionary
      #   as TableIDs for the ThesXrefs Physical Table
      setting :table_aliases, default: {
                                "343" => "Attributes",
                                "346" => "Geography",
                                "358" => "Statuses",
                                "361" => "Locations",
                                "469" => "StatusInact",
                                "604" => "GeoInact",
                                "650" => "AttrInact"
                              },
        reader: true

      # pass in client-specific transform classes to prepare thes_xrefs rows for
      #   merging
      setting :for_loans_prepper, default: nil, reader: true

      # pass in client-specific transform classes to merge thes_xrefs rows into
      #   target tables
      setting :for_loans_merge, default: nil, reader: true
    end
  end
end
