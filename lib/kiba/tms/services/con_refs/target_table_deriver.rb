# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      module ConRefs
        class TargetTableDeriver
          include Dry::Monads[:result]
          include Dry::Monads::Do.for(:call)

          def self.call(...)
            self.new(...).call
          end

          def initialize(mod: Tms::ConRefs,
                         table_getter: Tms::Data::CsvEnum
                        )
            @mod = mod
            @table_getter = table_getter
            @field = mod.split_on_column
          end

          def call
            table = yield get_table
            vals = yield rows_to_vals(table)

            Success(vals)
          end

          private

          attr_reader :mod, :table_getter, :field

          def get_table
            table_getter.call(mod: mod.for_table_source_job_key)
          end

          def rows_to_vals(rows)
            result = rows.map{ |row| row.key?(field) ? row[field] : nil }
              .compact
              .sort
              .uniq
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
