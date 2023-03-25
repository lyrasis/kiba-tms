# frozen_string_literal: true

require 'dry/monads'

module Kiba
  module Tms
    module Services
      module RegistrationSets
        # returns true if any LotID is associated with more than one
        #   RegistrationSetID
        class MultiSetLotChecker
          include Dry::Monads[:result]

          def self.call(...)
            self.new(...).call
          end

          attr_reader :mod

          def initialize(mod: :prep__registration_sets,
                         col: Tms::Data::Column
                        )
            @mod = mod
            @col = col
          end

          def call
            counts = col.new(mod: mod, field: :lotid)
              .value_counts
            return counts if counts.failure?

            Success(is_multival?(counts.value!))
          end

          private

          attr_reader :mod, :col

          def is_multival?(counts)
            cts = counts.values.uniq
            return false if  cts == [1]

            true
          end
        end
      end
    end
  end
end
