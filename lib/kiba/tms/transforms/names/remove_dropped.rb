# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class RemoveDropped
          def initialize
            @xform = if Tms.migration_status == :dev
              FilterRows::FieldEqualTo.new(
                action: :reject,
                field: :name,
                value: Tms::Names.dropped_name_indicator
              )
            else
              FilterRows::FieldPopulated.new(
                action: :keep,
                field: :name
              )
            end
          end

          def process(row)
            return row if xform.process(row)
          end

          private

          attr_reader :xform
        end
      end
    end
  end
end
