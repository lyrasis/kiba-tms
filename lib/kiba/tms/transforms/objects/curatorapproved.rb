# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Curatorapproved
          def initialize(positivestatus:)
            @source = :curatorapproved
            @target = :recordstatus
            @mapping = {
              "1" => positivestatus,
              "0" => nil
            }
          end

          def process(row)
            row[target] = mapping[row[source]]
            row.delete(source)
            row
          end

          private

          attr_reader :source, :target, :mapping
        end
      end
    end
  end
end
