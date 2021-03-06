# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        class MergeIntoAuthority
          def initialize(lookup:)
            sorter = Lookup::RowSorter.new(on: :rank)
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
                addresscountry: :addresscountry
              },
              sorter: sorter
            )
            @notemerger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: '%CR%%CR%',
              fieldmap: {
                address_namenote: :address_notes
              },
              sorter: sorter
            )
          end

          # @private
          def process(row)
            row = merger.process(row)
            row
          end
          
          private

          attr_reader :merger, :notemerger
        end
      end
    end
  end
end
