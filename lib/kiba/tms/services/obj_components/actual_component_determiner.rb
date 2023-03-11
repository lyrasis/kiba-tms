# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      module ObjComponents
        class ActualComponentDeterminer
          include Dry::Monads[:result]
          include Dry::Monads::Do.for(:call)

          def self.call(...)
            self.new(...).call
          end

          def initialize(mod: Tms::ObjComponents,
                         table_getter: Tms::Data::CsvEnum
                        )
            @mod = mod
            @table_getter = table_getter
          end

          def call
            return nil unless mod.used?

            table = yield table_getter.call(mod: mod)
            vals = yield accumulate_values(table)
            comps = yield select_components(vals)

            comps.empty? ? Success(false) : Success(true)
          end

          private

          attr_reader :mod, :table_getter

          def accumulate_values(table)
            acc = {}
            table.each do |row|
              obj = row[:objectid]
              acc[obj] = 0 unless acc.key?(obj)
              acc[obj] += 1
            end
          rescue StandardError => err
            Failure(err)
          else
            Success(acc)
          end

          def select_components(vals)
            result = vals.reject{ |_key, val| val == 1 }
          rescue StandardError => err
            Failure(err)
          else
            Success(result)
          end
        end
      end
    end
  end
end
