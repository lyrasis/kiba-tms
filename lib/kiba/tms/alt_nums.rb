# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AltNums
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable

      setting :initial_cleaner, default: nil, reader: true
      setting :description_cleaner, default: nil, reader: true
      setting :target_table_type_cleanup_needed,
        default: [],
        reader: true
      # Names of completed CSV files for any cleaned up (by client) target
      #   table worksheets. Expected to be found in `base_dir/supplied`
      #   directory
      # Format like:
      #   {
      #     'Objects'=>[
      #        'alt_num_types_for_objects_2023-01-18.csv',
      #        'alt_num_types_for_objects_2022-12-21.csv',
      #     ]
      #   }
      # Worksheets for a given target table are in newest-to-oldest order
      setting :target_table_type_cleanup_done,
        default: {},
        reader: true

      def cleaned_files_for(tablename)
        return [] unless target_table_type_cleanup_done.key?(tablename)

        target_table_type_cleanup_done[tablename]
      end

      def cleanup_done_for?(tablename)
        return false unless target_table_type_cleanup_done.key?(tablename)
        return false if target_table_type_cleanup_done[tablename].blank?

        true
      end
    end
  end
end
