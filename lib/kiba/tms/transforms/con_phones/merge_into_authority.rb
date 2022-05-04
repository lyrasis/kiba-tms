# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConPhones
        class MergeIntoAuthority
          def initialize(lookup:)
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: Tms.delim,
              null_placeholder: '%NULLVALUE%',
              fieldmap: {
                telephonenumber: :phone,
                telephonenumbertype: :phonetype,
                faxnumber: :fax,
                faxnumbertype: :faxtype
              }
            )
            @notemerger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: '%CR%%CR%',
              fieldmap: {
                phone_fax_namenote: :description
              }
            )
          end

          # @private
          def process(row)
            merger.process(row)
            notemerger.process(row)
          end
          
          private

          attr_reader :merger, :notemerger
        end
      end
    end
  end
end
