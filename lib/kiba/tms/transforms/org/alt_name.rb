# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Org
        class AltName
          include Kiba::Extend::Transforms::Helpers
          
          def initialize(lookup:)
            @merger = Tms::Transforms::ConAltNames::MergeIntoAuthority.new(lookup: lookup, authority_type: :org)
            @pref_name_field = Tms.constituents.preferred_name_field
          end

          # @private
          def process(row)
            merger.process(row)
            row[:var_termprefforlang] = '%NULLVALUE%' if Tms.names.set_term_pref_for_lang
            row[:var_termsource] = "TMS ConAltNames.#{pref_name_field}" if Tms.names.set_term_source
            row
          end
          
          private

          attr_reader :merger, :pref_name_field

        end
      end
    end
  end
end
