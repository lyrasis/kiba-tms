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

      # The merge-into-objects treatment to be applied to altnum
      #   values with no assigned type value
      setting :for_obj_accession_untyped_default_treatment,
        default: "acq_note",
        reader: true

      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
