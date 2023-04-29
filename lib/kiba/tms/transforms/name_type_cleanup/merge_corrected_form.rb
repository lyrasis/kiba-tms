# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class MergeCorrectedForm
          def initialize(lookup:, field:)
            @field = field
            @normfield = "#{field}_norm".to_sym
            @matchedfield = "#{field}_matched".to_sym
            @normer = Kiba::Extend::Transforms::Cspace::NormalizeForID.new(
              source: field,
              target: normfield
            )
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: normfield,
              fieldmap: {matchedfield => :correctname}
            )
            @deleter = Delete::Fields.new(
              fields: [normfield, matchedfield]
            )
          end

          def process(row)
            normer.process(row)
            merger.process(row)

            replace_field(row)
            deleter.process(row)
            row
          end

          private

          attr_reader :field, :normfield, :matchedfield,
            :normer, :merger

          def replace_field(row)
            merged = row[matchedfield]
            return if merged.blank?

            row[field] = merged
          end
        end
      end
    end
  end
end
