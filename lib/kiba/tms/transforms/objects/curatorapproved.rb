# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Curatorapproved
          def initialize(positivestatus: "curator approved")
            @source = :curatorapproved
            @mapping = {
              "1" => positivestatus,
              "0" => nil
            }
          end

          def process(row)
            val = row[source]
            return row if val.blank?

            row[source] = mapping[val]
            row
          end

          private

          attr_reader :source, :mapping
        end
      end
    end
  end
end
