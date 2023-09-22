# frozen_string_literal: true

module Kiba
  module Tms
    module ConRefs
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
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

      # ON MERGING CON REFS DATA
      #
      # General merging is controlled by the con_ref_name_merge_rules
      #  setting in the target table config module. These rules are
      #  used by the general purpose
      #  {Tms::Transforms::ConRefs::Merger}. If extra, more complex
      #  merge of con_refs data is required in addition to what is
      #  done by the general merger, additional merger transforms can
      #  be specified in the `Tms::ConRefsFor#{Target}.merger_xforms`
      #  setting.
      #
      # If you need to override/specially control the entire merge
      #  logic for a given target table, set its
      #  `con_ref_name_merge_rules` setting to nil in your client
      #  config.

      # Defines how auto-generated config settings are populated
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
