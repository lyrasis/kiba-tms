# frozen_string_literal: true

module Kiba
  module Tms
    module TextEntries
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[complete mixed textentryhtml languageid],
        reader: true
      extend Tms::Mixins::Tableable

      # Rows where none of these fields are populated will be dropped
      #   from the migration. For whatever reason, TMS seems to let
      #   folks make text entries with no content.
      #
      # @return [Array<Symbol>]
      setting :text_content_fields,
        default: %i[purpose remarks textentry],
        reader: true

      # Optional custom transform that, if defined, will be run in the prep
      #  job. Must be a kiba-compatible transform class that does not take
      #  initialization arguments.
      #
      # @return [nil, Class]
      setting :initial_cleaner, default: nil, reader: true

      setting :type_field, default: :texttype, reader: true
      setting :type_field_target, default: type_field, reader: true
      setting :mergeable_value_field, default: :textentry, reader: true
      setting :note_field, default: :textentry, reader: true

      # The merge-into-objects treatment to be applied to
      #   values with no assigned type value
      setting :for_obj_accession_untyped_default_treatment,
        default: "acq_note",
        reader: true
      setting :for_objects_untyped_default_treatment,
        default: "viewers_personal_exp_untyped",
        reader: true
      setting :for_obj_rights_untyped_default_treatment,
        default: "right_note",
        reader: true
      setting :for_reference_master_untyped_default_treatment,
        default: "citation_note_untyped",
        reader: true
      setting :for_term_master_thes_untyped_default_treatment,
        default: "term_note_untyped",
        reader: true

      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
