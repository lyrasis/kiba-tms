# frozen_string_literal: true

module Kiba
  module Tms
    module AltNums
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :type_field, default: :description, reader: true
      setting :type_field_target, default: :number_type, reader: true
      setting :mergeable_value_field, default: :altnum, reader: true
      setting :additional_occurrence_ct_fields,
        default: %i[remarks beginisodate endisodate],
        reader: true,
        constructor: ->(val) { val - empty_fields.keys }
      extend Tms::Mixins::MultiTableMergeable

      setting :initial_cleaner, default: nil, reader: true
      setting :description_cleaner, default: nil, reader: true

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

      # If a number type is mapped to `resource_id` treatment and the
      #   TMS AltNums `:remarks` field is populated, should the
      #   `:remarks` value be mapped to the CollectionSpace Citation
      #   Note field (with label indicating associated number/type)?
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
    end
  end
end
