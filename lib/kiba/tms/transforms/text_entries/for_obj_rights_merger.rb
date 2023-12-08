# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjRightsMerger
          def initialize
            @lookup = Tms::Mixins::MultiTableMergeable.get_merge_lookup(
              Tms::TextEntriesForObjRights
            )
            @treatments = Tms::TextEntriesForObjRights.treatment_mergers
              .transform_keys { |key| key.to_s }
              .transform_values { |val| val.new }
          end

          def process(row)
            merge_rows = lookup[row[:objectid]]
            return row unless merge_rows

            merge_rows.sort_by { |r| r[:sort].to_i }
              .each { |r| do_merge(row, r) }
            row
          end

          private

          attr_reader :lookup, :treatments

          def do_merge(row, mergerow)
            treatment_val = mergerow[:treatment]
            treatment = if treatment_val.blank?
              Tms::TextEntries.for_obj_rights_untyped_default_treatment
            else
              treatment_val
            end
            treatments[treatment]&.process(row, mergerow)
          end
        end
      end
    end
  end
end
