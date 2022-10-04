# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      # Returns unique type id values used in included data. Maps ids to their
      #   textual values. Removes no value values if not migrating.
      class UniqueTypeValuesUsed
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        def self.call(...)
          self.new(...).call
        end

        def initialize(mod:,
                       col_obj: Tms::Data::ColumnFromString,
                       failobj: Tms::Data::DeriverFailure,
                       table_getter: Tms::Data::CsvEnum)
          @mod = mod
          @table_getter = table_getter
          @col_obj = col_obj
          @failobj = failobj
          @used_in = mod.used_in
          @matcher = Regexp.new(Tms.no_value_type_pattern, Regexp::IGNORECASE)
        end

        def call
          unless mod.used?
            return Failure(
              failobj.new(mod: mod)
            )
          end
          unless used_in
          return Failure(
              failobj.new(mod: mod, sym: :not_used_in)
            )
          end

          lkup = yield table_getter.call(mod: mod)
          ids_used = yield used_values
          vals_used = yield vals_for_ids(ids_used, lkup)
          cleaned = yield clean_vals(vals_used)

          Success(cleaned)
        end

        private

        attr_reader :mod, :col_obj, :failobj, :used_in, :table_getter, :matcher

        def clean_vals(vals)
          return Success(vals) if Tms.migrate_no_value_types

          cleaned = vals.reject{ |val| val.match?(matcher) }
        rescue StandardError => err
          Failure(err)
        else
          Success(cleaned)
        end

        def used_values
          vals = used_in.map{ |col| col_obj.call(str: col).unique_values }
            .select(&:success?)
            .map(&:value!)
            .flatten
            .sort
            .uniq
        rescue StandardError => err
          Failure(err)
        else
          Success(vals)
        end

        def vals_for_ids(ids_used, lkup)
          vals = lkup.select{ |row| ids_used.any?(row[mod.id_field]) }
            .map{ |row| row[mod.type_field] }
        rescue StandardError => err
          Failure(err)
        else
          Success(vals)
        end
      end
    end
  end
end
