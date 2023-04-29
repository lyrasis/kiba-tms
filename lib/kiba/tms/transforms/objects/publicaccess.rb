# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Publicaccess
          def initialize
            @source = :publicaccess
            @target = :publishto
            @mapping = {
              "1"=>"CollectionSpace Public Browser",
              "0"=>"None"
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
