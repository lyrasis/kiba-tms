# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Places
        class ExplodeValues
          include Kiba::Extend::Transforms::Helpers

          def initialize(referencefields:)
            @referencefields = referencefields
            @fields = Tms::Places.source_fields - Tms::Places.worksheet_added_fields
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
            @rows = []
          end

          def process(row)
            reference_fields = get_reference_fields(row)
            getter.call(row)
              .each do |fieldname, value|
                base = {
                  fieldname: fieldname,
                  value: value,
                  fieldkey: "#{value}|||#{fieldname}"
                }
                rows << base.merge(reference_fields)
              end
            nil
          end

          def close
            rows.each { |row| yield row }
          end

          private

          attr_reader :referencefields, :fields, :getter, :rows

          def get_reference_fields(row)
            referencefields.map { |fld| [fld, row[fld]] }
              .to_h
          end
        end
      end
    end
  end
end
