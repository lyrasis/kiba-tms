# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConPhones
        class MergeIntoAuthority
          def initialize(lookup:)
            @phonemerger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :constituentid,
              delim: Tms.delim,
              null_placeholder: '%NULLVALUE%',
              fieldmap: {
                telephonenumber: :phone,
                telephonenumbertype: :phonetype
              }
            )
            @faxmerger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :constituentid,
              delim: Tms.delim,
              null_placeholder: '%NULLVALUE%',
              fieldmap: {
                faxnumber: :fax,
                faxnumbertype: :faxtype
              }
            )
            @notemerger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :constituentid,
              delim: '%CR%',
              fieldmap: {
                phone_fax_namenote: :description
              }
            )
          end

          # @private
          def process(row)
            phonemerger.process(row)
            faxmerger.process(row)
            notemerger.process(row)
          end

          private

          attr_reader :phonemerger, :faxmerger, :notemerger
        end
      end
    end
  end
end
