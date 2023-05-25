# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class DeletePatterns
        include Kiba::Extend::Transforms::Helpers

        def initialize(fields:, patterns:, conditions: nil)
          @fields = fields
          @patterns = patterns
          @conditions = conditions
          @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
            fields: fields
          )
        end

        def process(row)
          if conditions
            delete_patterns_from(row) if conditions.call(row)
          else
            delete_patterns_from(row)
          end
          row
        end

        private

        attr_reader :fields, :patterns, :conditions, :getter

        def delete_patterns_from(row)
          getter.call(row).each do |field, val|
            to_delete = patterns.select{ |patt| patt.match?(val) }
            next if to_delete.empty?

            delete_patterns_from_field(row, field, val, to_delete)
          end
        end

        def delete_patterns_from_field(row, field, val, to_delete)
          if to_delete.length == 1
            row[field] = val.gsub(to_delete[0], "")
          else
            row[field] = val.gsub(Regexp.union(*to_delete), "")
          end
        end
      end
    end
  end
end
