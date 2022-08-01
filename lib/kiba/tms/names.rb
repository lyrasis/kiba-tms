# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Names
      module_function
      
      extend Dry::Configurable
      setting :cleanup_iteration, default: nil, reader: true
      # whether to add "variant form" to name term flag field
      setting :flag_variant_form, default: false, reader: true
      setting :set_term_pref_for_lang, default: false, reader: true
      setting :set_term_source, default: false, reader: true

      setting :cleanup0, reader: true do
        setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
      end
      
      setting :compilation, reader: true do
        # compile :stmtresponsibility field from ReferenceMaster in names list
        setting :include_ref_stmt_resp, default: true, reader: true
        setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
        # fields to delete from name compilation report
        setting :delete_fields, default: [], reader: true
      end
    end
  end
end
