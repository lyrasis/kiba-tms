# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class MergeCorrectData
          def initialize(
            lookup:,
            delim: Tms.delim,
            nametarget: :correctname,
            typetarget: :correctauthoritytype,
            keycolumn: :constituentid
          )
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: keycolumn,
              fieldmap: {
                nametarget=>:correctname,
                typetarget=>:correctauthoritytype
              },
              delim: delim
            )
          end

          def process(row)
            merger.process(row)
            row
          end

          private

          attr_reader :merger
        end
      end
    end
  end
end
