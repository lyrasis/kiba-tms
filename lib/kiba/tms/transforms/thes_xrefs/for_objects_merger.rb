# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForObjectsMerger
          def initialize
            @lookup = Tms::Mixins::MultiTableMergeable.get_merge_lookup(
              Tms::ThesXrefsForObjects
            )
            @treatments = Tms::ThesXrefsForObjects.treatment_mergers
              .transform_keys { |key| key.to_s }
              .transform_values { |val| val.new }
          end

          def process(row)
            merge_rows = lookup[row[:objectid]]
            return row unless merge_rows

            merge_rows.sort_by { |r| r[:displayorder].to_i }
              .each { |r| do_merge(row, r) }
            row
          end

          private

          attr_reader :lookup, :treatments

          def do_merge(row, mergerow)
            treatment_val = mergerow[:treatment]
            treatment = if treatment_val.blank?
              Tms::ThesXrefs.for_objects_untyped_default_treatment.to_s
            else
              treatment_val
            end

            treatments[treatment].process(row, mergerow)
          end
        end
      end
    end
  end
end
