# frozen_string_literal: true

module Kiba
  module Tms
    module Associations
      extend Dry::Configurable

      module_function

      # Relation types that will not be included in the migration.
      #   Used to separate output of :prep__associations into
      #   :associations__in_migration and :associations__dropped.
      #   Format should be a Hash with String keys corresponding to
      #   :tablename values, and Array values (containing Strings
      #   corresponding to :relationtype values for that tablename.
      setting :omitted_types,
        default: {},
        reader: true

      extend Tms::Mixins::Tableable

      setting :for_table_source_job_key,
        default: :associations__in_migration,
        reader: true

      def type_field
        return nil unless Tms::Relationships.used?

        :relationtype
      end

      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
