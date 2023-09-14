# frozen_string_literal: true

module Kiba
  module Tms
    module TextEntries
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[complete mixed textentryhtml languageid],
        reader: true
      extend Tms::Mixins::Tableable

      # Rows where none of these fields are populated will be dropped
      #   from the migration. For whatever reason, TMS seems to let
      #   folks make text entries with no content.
      #
      # @return [Array<Symbol>]
      setting :text_content_fields,
        default: %i[purpose remarks textentry],
        reader: true

      # Optional custom transform that, if defined, will be run in the prep
      #  job. Must be a kiba-compatible transform class that does not take
      #  initialization arguments.
      #
      # @return [nil, Class]
      setting :initial_cleaner, default: nil, reader: true

      setting :type_field, default: :texttype, reader: true

      extend Tms::Mixins::MultiTableMergeable

      # pass in client-specific transform classes to prepare text_entry rows for
      #   merging
      setting :for_conditions_prepper,
        default: Tms::Transforms::TextEntries::ForConditions,
        reader: true
      setting :for_constituents_prepper,
        default: Tms::Transforms::TextEntries::ForConstituents,
        reader: true
      setting :for_exhibitions_prepper,
        default: Tms::Transforms::TextEntries::ToNote,
        reader: true
      setting :for_exh_obj_xrefs_prepper, default: nil, reader: true
      setting :for_loan_obj_xrefs_prepper,
        default: Tms::Transforms::TextEntries::ToNote,
        reader: true
      setting :for_loans_prepper, default: nil, reader: true
      setting :for_objects_prepper, default: nil, reader: true
      setting :for_obj_accession_prepper, default: nil, reader: true
      setting :for_obj_components_prepper, default: nil, reader: true
      setting :for_obj_context_prepper, default: nil, reader: true
      setting :for_obj_deaccession_prepper, default: nil, reader: true
      setting :for_obj_rights_prepper, default: nil, reader: true
      setting :for_reference_master_prepper, default: nil, reader: true
      setting :for_shipments_prepper, default: nil, reader: true
      setting :for_shipment_steps_prepper, default: nil, reader: true
      setting :for_term_master_thes_prepper, default: nil, reader: true

      # pass in client-specific transform classes to merge text_entry rows into
      #   target tables
      setting :for_conditions_merge,
        default: Tms::Transforms::TextEntries::MergeConditions,
        reader: true
      setting :for_constituents_merge,
        default: Tms::Transforms::TextEntries::MergeConstituents,
        reader: true
      setting :for_exhibitions_merge,
        default: Tms::Transforms::TextEntries::MergeExhibitions,
        reader: true
      setting :for_exh_obj_xrefs_merge,
        default: Tms::Transforms::TextEntries::MergeExhObjXrefs,
        reader: true
      setting :for_loan_obj_xrefs_merge,
        default: Tms::Transforms::TextEntries::MergeLoanObjXrefs,
        reader: true
      setting :for_loans_merge, default: nil, reader: true
      setting :for_objects_merge, default: nil, reader: true
      setting :for_obj_accession_merge, default: nil, reader: true
      setting :for_obj_components_merge, default: nil, reader: true
      setting :for_obj_context_merge, default: nil, reader: true
      setting :for_obj_deaccession_merge, default: nil, reader: true
      setting :for_obj_rights_merge, default: nil, reader: true
      setting :for_reference_master_merge, default: nil, reader: true
      setting :for_shipments_merge, default: nil, reader: true
      setting :for_shipment_steps_merge, default: nil, reader: true
      setting :for_term_master_thes_merge, default: nil, reader: true
    end
  end
end
