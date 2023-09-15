# frozen_string_literal: true

module Kiba
  module Tms
    module Names
      module_function

      extend Dry::Configurable

      # Whether to check the termPrefForLang field/box in the term
      #   field group for the preferred form of name.
      setting :set_term_pref_for_lang, default: true, reader: true

      # Whether to populate the CS name term flag field with "variant
      #   form" in the term field group for variant names.
      #
      # This defaults to false because, in general it is assumed that
      #   any term field group without termPrefForLang set is a
      #   variant term
      setting :flag_variant_form, default: false, reader: true

      # Whether the term source field is populated for each term field
      #   group.
      #
      # By default, while the migration is being developed (on the
      #   staging/training instance), this is set to true. The TMS
      #   table/field from which a name came is used. This is used for
      #   debugging the migration.
      #
      # By default, this is set to false when we do the production
      #   migration.
      setting :set_term_source,
        default: false,
        reader: true,
        constructor: ->(_val) { true if Tms.migration_status == :dev }

      # Authority type (:contype) assigned to names with no type (if
      #   client does not provide one)
      setting :untyped_default, default: "Person", reader: true

      # @return [String] Value substituted in for any names marked to
      #   be dropped from migration, while the migration is run in
      #   :dev mode. In :prod mode, the names are dropped
      setting :dropped_name_indicator,
        default: "DROPPED FROM MIGRATION",
        reader: true

      setting :compilation, reader: true do
        # Whether to compile :stmtresponsibility field from
        # ReferenceMaster in names list You probably only want to set
        # this to true if ConXrefDetails target tables do not include
        # ReferenceMaster
        setting :include_ref_stmt_resp, default: false, reader: true
        setting :multi_source_normalizer,
          default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
          reader: true
        # fields to delete from name compilation report @return
        # [Array<Symbol>] unmigratable fields removed by default
        setting :delete_fields, default: [], reader: true
      end

      def used?
        true if Tms::Constituents.used?
      end
    end
  end
end
