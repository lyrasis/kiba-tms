# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConEmail
        class MergeIntoAuthority
          def initialize(lookup:)
            @emailmerger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: Tms.delim,
              null_placeholder: '%NULLVALUE%',
              fieldmap: {
                email: :email,
                emailtype: :emailtype
              }
            )
            @webmerger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: Tms.delim,
              null_placeholder: '%NULLVALUE%',
              fieldmap: {
                webaddress: :web,
                webaddresstype: :webtype
              }
            )
            @notemerger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: '%CR%%CR%',
              fieldmap: {
                email_web_namenote: :description
              }
            )
          end

          # @private
          def process(row)
            emailmerger.process(row)
            webmerger.process(row)
            notemerger.process(row)
          end
          
          private

          attr_reader :emailmerger, :webmerger, :notemerger
        end
      end
    end
  end
end
