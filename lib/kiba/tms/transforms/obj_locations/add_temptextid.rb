# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class AddTemptextid
          def initialize(target:, mode: :orig)
            @target = target
            @fields = set_fields(mode)
            @combiner = CombineValues::FromFieldsWithDelimiter.new(
              sources: fields,
              target: target,
              sep: ' ',
              delete_sources: false,
              prepend_source_field_name: true
            )
          end

          def process(row)
            combiner.process(row)
            row
          end

          private

          attr_reader :target, :fields, :combiner

          def set_fields(mode)
            if mode == :orig
              [:temptext, Tms::ObjLocations.fulllocid_fields].flatten
            else
              [:temptext, Tms::ObjLocations.fulllocid_fields_hier].flatten
            end
          end
        end
      end
    end
  end
end
