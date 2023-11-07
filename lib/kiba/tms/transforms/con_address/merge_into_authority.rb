# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        class MergeIntoAuthority
          def initialize(lookup:)
            @mergers = [
              Merge::MultiRowLookup.new(
                lookup: lookup,
                keycolumn: :constituentid,
                delim: Tms.delim,
                null_placeholder: "%NULLVALUE%",
                fieldmap: {
                  addressplace1: :addressplace1,
                  addressplace2: :addressplace2,
                  addressmunicipality: :city,
                  addressstateorprovince: :state,
                  addresspostcode: :zipcode,
                  addresscountry: :addresscountry
                },
                sorter: Lookup::RowSorter.new(on: :rank)
              ),
              Merge::MultiRowLookup.new(
                lookup: lookup,
                keycolumn: :constituentid,
                delim: Tms.notedelim,
                fieldmap: {
                  address_namenote: :address_notes
                },
                sorter: Lookup::RowSorter.new(on: :rank)
              )
            ]
            @prepender = Prepend::ToFieldValue.new(
              field: :address_namenote,
              value: Tms::ConAddress.note_prefix
            )
          end

          def process(row)
            mergers.each { |merger| merger.process(row) }
            prepender.process(row)
            row
          end

          private

          attr_reader :mergers, :prepender
        end
      end
    end
  end
end
