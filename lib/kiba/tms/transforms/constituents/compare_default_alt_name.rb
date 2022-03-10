# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class CompareDefaultAltName
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @name = Kiba::Tms.config.constituents.preferred_name_field
            @default_alt_name = "alt_#{name}".to_sym
            @target = "#{name}_compare".to_sym
          end

          def process(row)
            values = field_values(row: row, fields: [name, default_alt_name])
              .values
              .map(&:downcase)
            if values.empty?
              row[target] = 'y'
            elsif values.length == 1
              row[target] = 'n'
            elsif values.uniq.length == 1
              row[target] = 'y'
            else
              row[target] = 'n'
            end
            row
          end

          private

          attr_reader :name, :default_alt_name, :target

        end
      end
    end
  end
end
