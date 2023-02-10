# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TextEntries
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[complete mixed textentryhtml languageid],
        reader: true
      extend Tms::Mixins::Tableable

      extend Tms::Mixins::MultiTableMergeable


      # pass in client-specific transform classes to prepare text_entry rows for
      #   merging
      setting :for_conditions_prepper,
        default: Tms::Transforms::TextEntries::ForConditions,
        reader: true
      setting :for_constituents_prepper, default: nil, reader: true
      setting :for_exhibitions_prepper, default: nil, reader: true
      setting :for_exh_obj_xrefs_prepper, default: nil, reader: true
      setting :for_loan_obj_xrefs_prepper, default: nil, reader: true
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
      setting :for_constituents_merge, default: nil, reader: true
      setting :for_exhibitions_merge, default: nil, reader: true
      setting :for_exh_obj_xrefs_merge, default: nil, reader: true
      setting :for_loan_obj_xrefs_merge, default: nil, reader: true
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
