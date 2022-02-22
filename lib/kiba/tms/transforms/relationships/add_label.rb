# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Relationships
        class AddLabel
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @sources = %i[relation1 relation2]
            @target = :relationship_label
          end

          def process(row)
            row[@target] = nil
            vals = field_values(row: row, fields: @sources)
            return row if vals.empty?
            
            row[@target] = get_label(vals)  
            row
          end

          private

          def different?(vals)
            !same?(vals)
          end

          def get_label(vals)
            return vals.values.uniq.first if same?(vals)

            vals.values.join('/')
          end
          
          def same?(vals)
            vals.values.uniq.length == 1
          end
        end
      end
    end
  end
end
