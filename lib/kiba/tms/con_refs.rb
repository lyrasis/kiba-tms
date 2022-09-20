# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConRefs
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :con_refs__create, reader: true
      setting :delete_fields, default: %i[conxrefdetailid], reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable
      
      setting :target_tables, default: %w[], reader: true
      setting :for_table_source_job_key, default: :con_refs__prep, reader: true
      extend Tms::Mixins::MultiTableMergeable

      setting :migrate_inactive, default: true, reader: true
    end
  end
end
