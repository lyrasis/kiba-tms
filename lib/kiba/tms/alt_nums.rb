# frozen_string_literal: true

module Kiba
  module Tms
    module AltNums
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :type_field, default: :description, reader: true
      setting :type_field_target, default: :number_type, reader: true
      setting :note_field, default: :remarks, reader: true
      setting :mergeable_value_field, default: :altnum, reader: true
      setting :additional_occurrence_ct_fields,
        default: %i[remarks beginisodate endisodate],
        reader: true,
        constructor: ->(val) { val - empty_fields.keys }
      extend Tms::Mixins::MultiTableMergeable

      setting :initial_cleaner, default: nil, reader: true
      setting :description_cleaner, default: nil, reader: true

      # The merge-into-objects treatment to be applied to altnum
      #   values with no assigned type value
      setting :for_objects_untyped_default_treatment,
        default: "other_number",
        reader: true

      # Whether `altnum_annotation` or `numtyped_annotation` treatments are
      #   used in the project. Used to determine whether we need to handle
      #   the resulting intermediate fields in object record processing
      #
      # @return [Boolean]
      setting :for_objects_annotation_treatments_used,
        default: false,
        reader: true

      # Prefix added to `annotationType` vocabulary terms for alt number types
      #   assigned the `numtype_annotation` treatment.
      #
      # The idea behind adding a prefix like "numtype: " is that, when
      #   doing CollectionSpace data entry, in the Annotation type
      #   field, you can type `numtype:` and the choices in the term
      #   pick-list will be narrowed down to valid number type terms.
      #   Also, this allows all the number type terms to be easily
      #   reviewed and managed together in the interface for managing
      #   the Annotation Type vocabulary
      #
      # @return [String]
      setting :for_objects_numtype_annotation_type_prefix,
        default: "numtype: ",
        reader: true

      # Value set as the Annotation Type field value when an alt number type
      #   is treated as `altnum_annotation`.
      setting :for_objects_altnum_annotation_type,
        default: "alternate number",
        reader: true

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
