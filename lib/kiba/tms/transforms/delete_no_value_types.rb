# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class DeleteNoValueTypes
        def initialize(field:)
          @field = field
          @active = Tms.migrate_no_value_types ? false : true
          @filter = FilterRows::FieldMatchRegexp.new(
            action: :reject,
            field: field,
            ignore_case: true,
            match: Tms.no_value_type_pattern
          )
        end

        def process(row)
          return row unless active

          filter.process(row)
        end

        private

        attr_reader :field, :active, :filter
      end
    end
  end
end
