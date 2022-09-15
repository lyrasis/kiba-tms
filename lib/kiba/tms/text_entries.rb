# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TextEntries
      extend Dry::Configurable
      module_function

      setting :delete_fields, default: %i[complete mixed textentryhtml languageid], reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable

      setting :target_tables, default: [], reader: true
      extend Tms::Mixins::MultiTableMergeable

      setting :checkable, default: {
        needed_table_transform_settings: Proc.new{ check_needed_table_transform_settings },
        undefined_table_transforms: Proc.new{ check_undefined_table_transforms }
      },
        reader: true

      # pass in client-specific transform classes to prepare text_entry rows for merging
      setting :for_conditions_transform, default: nil, reader: true
      setting :for_constituents_transform, default: nil, reader: true
      setting :for_exhibitions_transform, default: nil, reader: true
      setting :for_exh_obj_xrefs_transform, default: nil, reader: true
      setting :for_loan_obj_xrefs_transform, default: nil, reader: true
      setting :for_loans_transform, default: nil, reader: true
      setting :for_objects_transform, default: nil, reader: true
      setting :for_obj_accession_transform, default: nil, reader: true
      setting :for_obj_components_transform, default: nil, reader: true
      setting :for_obj_context_transform, default: nil, reader: true
      setting :for_obj_deaccession_transform, default: nil, reader: true
      setting :for_obj_rights_transform, default: nil, reader: true
      setting :for_reference_master_transform, default: nil, reader: true
      setting :for_shipments_transform, default: nil, reader: true
      setting :for_shipment_steps_transform, default: nil, reader: true
      setting :for_term_master_thes_transform, default: nil, reader: true
    end
  end
end
