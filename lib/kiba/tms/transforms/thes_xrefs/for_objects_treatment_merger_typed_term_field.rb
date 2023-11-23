# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForObjectsTreatmentMergerTypedTermField
          include Tms::Transforms::ValueAppendable

          def initialize
            @target_base = "term_"
            @source_mapping = {
              termused: "used",
              termpreferred: "preferred",
              termsource: "source",
              remarks: "note"
            }
          end

          def process(row, mergerow)
            type = mergerow[:thesxreftype]
            source_mapping.each do |srcfield, targetsuffix|
              handle_field(row, mergerow, type, srcfield, targetsuffix)
            end
            row
          end

          private

          attr_reader :target_base, :source_mapping

          def handle_field(row, mergerow, type, source, targetsuffix)
            fieldval = mergerow[source]
            val = fieldval.blank? ? "%NULLVALUE%" : fieldval
            target = "#{target_base}#{type}#{targetsuffix}"
              .delete_suffix("_")
              .to_sym
            append_value(row, target, val, Tms.delim)
          end
        end
      end
    end
  end
end
