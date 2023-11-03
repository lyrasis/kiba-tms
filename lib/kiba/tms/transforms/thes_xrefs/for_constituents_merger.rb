# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsMerger
          def initialize
            @lookup = Tms::Mixins::MultiTableMergeable.get_merge_lookup(
              Tms::ThesXrefsForConstituents
            )
            @treatments = Tms::ThesXrefsForConstituents.treatment_mergers
              .transform_keys { |key| key.to_s }
              .transform_values { |val| val.new }
          end

          def process(row)
            merge_rows = lookup[row[:constituentid]]
            return row unless merge_rows

            merge_rows.sort_by { |r| r[:displayorder].to_i }
              .each { |r| do_merge(row, r) }
            row
          end

          private

          attr_reader :lookup, :treatments

          def do_merge(row, mergerow)
            treatment_val = mergerow[:treatment]
            if treatment_val.blank?
              treatment = Tms::ThesXrefs.for_constituents_untyped_default_treatment
              args = {}
            elsif treatment_val.match?(
              /^type_labeled_(?:internal|public)_note/
            )
              parts = treatment_val.split("_")
              treatment = "type_labeled_note"
              args = {suffix: parts.last, type: parts[2]}
            else
              treatment = treatment_val
              args = {}
            end

            if args.empty?
              treatments[treatment].process(row, mergerow)
            else
              treatments[treatment].process(row, mergerow, **args)
            end
          end
        end
      end
    end
  end
end
