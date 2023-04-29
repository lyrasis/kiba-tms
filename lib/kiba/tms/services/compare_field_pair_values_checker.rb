# frozen_string_literal: true

require "csv"
require "dry/monads"
require "dry/monads/do"

module Kiba
  module Tms
    module Services
      # Compares value of two fields and produces a to-do checkable
      #   message if they are different for any row
      class CompareFieldPairValuesChecker
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        def self.call(...)
          new(...).call
        end

        def initialize(mod:,
          fields:,
          failobj: Tms::Data::DeriverFailure,
          table_getter: Tms::Data::CsvEnum)
          @mod = mod
          @fields = fields
          @table_getter = table_getter
          @failobj = failobj
        end

        def call
          unless mod.used?
            return Failure(
              failobj.new(mod: mod)
            )
          end

          lkup = yield table_getter.call(mod: mod)
          all_same = yield pair_checker(lkup)

          all_same ? Success(nil) : Success(diff_msg)
        end

        private

        attr_reader :mod, :fields, :failobj, :table_getter

        def diff_msg
          "Different values in #{fields[0]} and #{fields[1]}"
        end

        def pair_checker(rows)
          all_same = true
          rows.each do |row|
            break unless all_same

            all_same = false unless row[fields[0]] == row[fields[1]]
          end
        rescue => err
          results << Failure([name, err])
        else
          Success(all_same)
        end
      end
    end
  end
end
