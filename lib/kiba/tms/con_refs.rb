# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ConRefs
      extend Dry::Configurable

      module_function

      setting :source_job_key, default: :con_refs__create, reader: true
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[conxrefdetailid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :for_table_source_job_key,
        default: :con_refs__type_match,
        reader: true
      setting :split_on_column, default: :role_type, reader: true
      extend Tms::Mixins::MultiTableMergeable

      def auto_generate_target_tables
        false
      end

      setting :migrate_inactive, default: true, reader: true

      # pass in client-specific, target-table-specific transform classes to
      #   clean/prepare data for merging
      setting :for_exh_venues_xrefs_prepper, default: nil, reader: true
      setting :for_exhibitions_prepper, default: nil, reader: true
      setting :for_loans_in_prepper, default: nil, reader: true
      setting :for_loans_out_prepper, default: nil, reader: true
      setting :for_media_renditions_prepper, default: nil, reader: true
      setting :for_obj_accession_prepper, default: nil, reader: true
      setting :for_obj_rights_prepper, default: nil, reader: true
      setting :for_objects_prepper,
        default: Tms::Transforms::ConRefs::ForObjects,
        reader: true
      setting :for_reference_master_prepper, default: nil, reader: true
      setting :for_shipment_steps_prepper, default: nil, reader: true
      setting :for_shipments_prepper, default: nil, reader: true

      # Pass in arrays of client-specific, target-table-specific transform
      #   classes to merge rows into target tables
      #
      # These transforms should only handle merging not controlled by
      #  con_ref_name_merge_rules setting in the target table config module. If
      #  you need to override/specially control the entire merge logic for a
      #  target table, set its `con_ref_name_merge_rules` setting to nil in your
      #  client config.
      setting :for_exh_venues_xrefs_merge, default: nil, reader: true
      setting :for_exhibitions_merge, default: nil, reader: true
      setting :for_loans_in_merge, default: nil, reader: true
      setting :for_loans_out_merge, default: nil, reader: true
      setting :for_media_renditions_merge, default: nil, reader: true
      setting :for_obj_accession_merge, default: nil, reader: true
      setting :for_obj_rights_merge, default: nil, reader: true
      setting :for_objects_merge, default: nil, reader: true
      setting :for_reference_master_merge, default: nil, reader: true
      setting :for_shipment_steps_merge, default: nil, reader: true
      setting :for_shipments_merge, default: nil, reader: true

      setting :configurable,
        default: {
          target_tables: proc {
            Tms::Services::ConRefs::TargetTableDeriver.call
          }
        },
        reader: true
    end
  end
end
