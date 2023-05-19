# frozen_string_literal: true

module Kiba
  module Tms
    module Names
      module_function

      extend Dry::Configurable

      # whether to add "variant form" to name term flag field
      setting :flag_variant_form, default: false, reader: true
      setting :set_term_pref_for_lang, default: true, reader: true
      setting :set_term_source, default: false, reader: true,
        constructor: ->(value) { true if Tms.migration_status == :dev }
      # Authority type (:contype) assigned to names with no type (if client does
      #   not provide one)
      setting :untyped_default, default: "Person", reader: true

      setting :compilation, reader: true do
        # Whether to compile :stmtresponsibility field from ReferenceMaster in names list
        # You probably only want to set this to true if ConXrefDetails target tables do not include
        #   ReferenceMaster
        setting :include_ref_stmt_resp, default: false, reader: true
        setting :multi_source_normalizer,
          default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
        # fields to delete from name compilation report
        # @return [Array<Symbol>] unmigratable fields removed by default
        setting :delete_fields, default: [], reader: true
      end
    end
  end
end
