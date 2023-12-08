# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerContentOtherTyped
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @valuesource = :textentry
            @valuetarget = :te_contentother
            @typesource = :texttype
            @typetarget = :te_contentothertype
            @delim = Tms.delim
          end

          def process(row, mergerow)
            append_value(row, valuetarget, mergerow[valuesource], delim)
            append_value(row, typetarget, mergerow[typesource], delim)
            row
          end

          private

          attr_reader :valuesource, :valuetarget, :typesource, :typetarget,
            :delim
        end
      end
    end
  end
end
