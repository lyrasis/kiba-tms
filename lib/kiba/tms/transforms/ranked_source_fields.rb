# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Use case: you end up with multiple fields that mean the same thing coming
      #   in from the TMS side, and the CS target is single value.
      #
      # Example: :accessionisodate value from ObjAccession row is different from
      #   same field in linked RegistrationSets row. We can say we prefer the
      #   RegistrationSets value if there is one, but if the RegistrationSets
      #   field is blank and the ObjAccession field has a value, that value
      #   will be used
      class RankedSourceFields
        # @param fields [Array<Symbol>] **ordered** - first is most highly
        #    preferred; last is least preferred
        # @param target [Symbol]
        def initialize(fields:,
          target:,
          getter: Kiba::Extend::Transforms::Helpers::FieldValueGetter)
          @fields = fields
          @target = target
          @deletes = fields - [target]
          @getter = getter.new(fields: fields)
        end

        def process(row)
          row[target] = preferred_value(row)
          deletes.each { |field| row.delete(field) }
          row
        end

        private

        attr_reader :fields, :target, :deletes, :getter

        def preferred_value(row)
          got = getter.call(row)
          return nil if got.empty?

          got.values
            .first
        end
      end
    end
  end
end
