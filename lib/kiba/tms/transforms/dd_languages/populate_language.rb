# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module DDLanguages
        class PopulateLanguage

          def initialize
            @sources = %i[mnemonic label]
            @target = Tms::DDLanguages.type_field
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: sources
              )
          end

          def process(row)
            row[target] = nil
            vals = getter.call(row).values
            sources.each{ |field| row.delete(field) }
            return row if vals.empty?

            row[target] = vals.first
            row
          end

          private

          attr_reader :sources, :target, :getter
        end
      end
    end
  end
end
