# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module OneToOneAcq
        class AcqRefNumDeriver
          def initialize
            @source = :objectnumber
            @target = :acqrefnum
            @delim = '.'
          end

          def process(row)
            objnum = row[source]

            if objnum[delim]
              acqnum = objnum.split('.')[0..-2]
                .join('.')

              row[target] = acqnum
            else
              row[target] = objnum
            end
            row
          end

          private

          attr_reader :source, :target, :delim
        end
      end
    end
  end
end
