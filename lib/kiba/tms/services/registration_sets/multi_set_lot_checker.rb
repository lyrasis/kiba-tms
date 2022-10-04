# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module RegistrationSets
        # returns true if any LotID is associated with more than one
        #   RegistrationSetID
        class MultiSetLotChecker
          def self.call(...)
            self.new(...).call
          end

          attr_reader :mod

          def initialize(mod: Tms::RegistrationSets,
                         col: Tms::Data::Column
                        )
            @mod = mod
            @col = col
          end

          def call
            counts = col.new(mod: mod, field: :lotid)
              .value_counts
            return counts if counts.failure?

            get_result(counts.value!)
          end

          private

          attr_reader :mod, :col

          def get_result(counts)
            cts = counts.values.uniq
            true unless cts == [1]
          end
        end
      end
    end
  end
end
