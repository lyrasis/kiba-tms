# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConRefs
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :con_refs__create, reader: true
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

      setting :configurable, default: {
        target_tables: proc{ Tms::Services::ConRefs::TargetTableDeriver.call }
      },
        reader: true
    end
  end
end
