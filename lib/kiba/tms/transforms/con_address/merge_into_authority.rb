# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        class MergeIntoAuthority
          include Kiba::Extend::Transforms::Helpers
          
          def initialize(lookup:)
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: Tms.delim,
              null_placeholder: '%NULLVALUE%',
              fieldmap: {
                addressplace1: :addressplace1,
                addressplace2: :addressplace2,
                addressmunicipality: :city,
                addressstateorprovince: :state,
                addresspostcode: :zipcode,
                addresscountry: :country,
                note_address: :address_notes
              }
            )
          end

          # @private
          def process(row)
            row = merger.process(row)
            row
          end
          
          private

          attr_reader :merger
        end
      end
    end
  end
end
