# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      module MediaMaster
        class DisplayIsPrimaryDeriver
          include Dry::Monads[:result]
          include Dry::Monads::Do.for(:call)

          def self.call(...)
            self.new(...).call
          end

          def initialize(csver: Tms::Data::CsvEnum)
            @mod = Tms::MediaMaster
            @csver = csver
          end

          def call
            csv = yield csver.call(mod: mod)
            result = yield compare_fields(csv)

            Success(result)
          end

          private

          attr_reader :mod, :csver

          def compare_fields(csv)
            result = do_compare(csv)
          rescue StandardError => err
            Failure(Tms::Data::DeriverFailure.new(mod: mod, err: err))
          else
            Success(result)
          end

          def do_compare(csv)
            result = true
            csv.each do |row|
              next if row[:displayrendid] == row[:primaryrendid]

              result = false
              break
            end
            result
          end
        end
      end
    end
  end
end
