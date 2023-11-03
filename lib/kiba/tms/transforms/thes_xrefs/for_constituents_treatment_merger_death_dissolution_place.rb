# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsTreatmentMergerDeathDissolutionPlace
          include Tms::Transforms::ValueAppendable

          def initialize
            @target_base = "term_death_dissolution_place_"
            @source_mapping = {
              termpreferred: "preferred",
              termused: "used",
              remarks: "note"
            }
          end

          def process(row, mergerow)
            source_mapping.each do |srcfield, targetsuffix|
              handle_field(row, mergerow, srcfield, targetsuffix)
            end
            row
          end

          private

          attr_reader :target_base, :source_mapping

          def handle_field(row, mergerow, source, targetsuffix)
            fieldval = mergerow[source]
            val = fieldval.blank? ? "%NULLVALUE%" : fieldval
            target = "#{target_base}#{targetsuffix}".to_sym
            append_value(row, target, val, Tms.delim)
          end
        end
      end
    end
  end
end
