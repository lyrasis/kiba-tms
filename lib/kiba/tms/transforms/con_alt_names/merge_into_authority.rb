# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAltNames
        class MergeIntoAuthority
          include Kiba::Extend::Transforms::Helpers
          
          def initialize(lookup:)
            @pref_name_field = Tms.constituents.preferred_name_field
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: Tms.delim,
              null_placeholder: '%NULLVALUE%',
              fieldmap: {
                alt_termdisplayname: pref_name_field,
                alt_salutation: :salutation,
                alt_title: :nametitle,
                alt_forename: :firstname,
                alt_middlename: :middlename,
                alt_surname: :lastname,
                alt_nameadditions: :suffix,
                alt_termsourcenote: :remarks,
                alt_termflag: :nametype
              }
            )
          end

          # @private
          def process(row)
            merger.process(row)
          end
          
          private

          attr_reader :pref_name_field, :merger
        end
      end
    end
  end
end
