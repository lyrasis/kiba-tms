# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class CollapseMultisourceField
        def initialize(fields:,
                       target:,
                       getter: Kiba::Extend::Transforms::Helpers::FieldValueGetter
                      )
          @fields = fields
          @target = target
          @deletes = fields - [target]
          @getter = getter.new(fields: fields)
        end

        def process(row)
          return row if unnecessary?

          vals = getter.call(row)
            .values
            .uniq
            .join(Tms.delim)
          row[target] = vals

          deletes.each{ |field| row.delete(field) }
          row
        end

        private

        attr_reader :fields, :target, :deletes, :getter

        def unnecessary?
          true if fields.length == 1 &&
            fields.first == target
        end
      end
    end
  end
end
