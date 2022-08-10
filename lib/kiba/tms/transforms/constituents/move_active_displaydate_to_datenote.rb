# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MoveActiveDisplaydateToDatenote
          def initialize
            @source = :displaydate
            @prefix = 'active'
            @target = :datenote
          end
          
          def process(row)
            dd = row[source]
            return row unless eligible?(dd)

            row[target] = dd
            row[source] = nil
            row
          end

          private

          attr_reader :source, :prefix, :target

          def eligible?(dd)
            return false if dd.blank?

            true if dd.downcase.start_with?(prefix)
          end
        end
      end
    end
  end
end
