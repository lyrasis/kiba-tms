# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConservationTreatments
        class CreateCondLineItemNhrs
          def initialize
            @table_type_lookup = {
              "Objects"=>"collectionobjects"
            }
          end

          def process(row)
            [
              produce_obj_or_other_rel(row),
              produce_condition_rel(row)
            ].each{ |outrow| yield outrow }
            nil
          end

          private

          attr_reader :table_type_lookup

          def produce_obj_or_other_rel(row)
            {
              item1_id: row[:recordnumber],
              item1_type: table_type_lookup[row[:tablename]],
              item2_id: row[:conservationnumber],
              item2_type: "conservation"
            }
          end

          def produce_condition_rel(row)
            {
              item1_id: row[:conditioncheckrefnumber],
              item1_type: "conditionchecks",
              item2_id: row[:conservationnumber],
              item2_type: "conservation"
            }
          end
        end
      end
    end
  end
end
