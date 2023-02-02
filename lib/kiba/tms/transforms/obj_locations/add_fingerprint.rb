# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class AddFingerprint
          def initialize(delete_sources: false)
            @xform = CombineValues::FromFieldsWithDelimiter.new(
              sources: Tms::ObjLocations.content_fields,
              target: :fingerprint,
              sep: ' ',
              prepend_source_field_name: true,
              delete_sources: delete_sources
            )
          end

          def process(row)
            xform.process(row)
            row
          end

          private

          attr_reader :xform
        end
      end
    end
  end
end
