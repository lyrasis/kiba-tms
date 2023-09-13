# frozen_string_literal: true

module Kiba::Tms::AltNums
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

  # pass in client-specific transform classes to prepare rows for
  #   merging
  setting :for_constituents_prepper, default: nil, reader: true
  setting :for_objects_prepper, default: nil, reader: true
  setting :for_reference_master_prepper, default: nil, reader: true

  # pass in client-specific transform classes to merge rows into
  #   target tables
  setting :for_constituents_merge, default: nil, reader: true
  setting :for_objects_merge, default: nil, reader: true
  setting :for_reference_master_merge, default: nil, reader: true

  # If a number type is mapped to `resource_id` treatment and the TMS AltNums
  #   `:remarks` field is populated, should the `:remarks` value be mapped to
  #   the CollectionSpace Citation Note field (with label indicating associated
  #   number/type)?
  setting :reference_master_resource_id_remarks_to_note,
    default: false,
    reader: true

  # If a number type is mapped to `resource_id` treatment and either
  #   of the TMS AltNums `:beginisodate` or `:endisodate` fields is
  #   populated, should the date value(s) be mapped to the
  #   CollectionSpace Citation Note field (with label indicating
  #   associated number/type)?
  setting :reference_master_resource_id_dates_to_note,
    default: false,
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
