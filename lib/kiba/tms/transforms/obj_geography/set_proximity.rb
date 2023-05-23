# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjGeography
        # If :proximity_in_note = true, this transform removes terms like
        #   "near" or "close to" from the value that will become an
        #   authority term, moving it to a new :proximity field that will
        #   be mapped to :assocplacetype or :objectproductionplacerole
        #   fields
        class SetProximity
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @fields = Tms::ObjGeography.content_fields
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
            @target = :proximity
          end

          def process(row)
            row
          end

          private

          attr_reader :fields, :getter, :target
        end
      end
    end
  end
end
