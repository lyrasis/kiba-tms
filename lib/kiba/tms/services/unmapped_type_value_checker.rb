# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Services
      class UnmappedTypeValueChecker
        def self.call(...)
          self.new(...).call
        end

        def initialize(mod)
          @mod = mod
          @mapped = mod.mappings.keys
          @value_getter = Tms::Services::UniqueTypeValuesUsed.new(mod)
          @idfield = mod.id_field
          @typefield = mod.type_field
          @migrate_no_val = Tms.migrate_no_value_types
          @no_val_pattern = Tms.no_value_type_pattern
          @unmapped = get_unmapped
        end

        def call
          return nil unless mod.used?
          return nil if unmapped.empty?

          result = unmapped_values
          return nil if result.values.all?(&:empty?)

          report_format(result)
        end

        private

        attr_reader :mod, :mapped, :value_getter, :idfield, :typefield, :migrate_no_val, :no_val_pattern, :unmapped

        def get_unmapped
          ids = {}
          CSV.foreach(mod.table.supplied_data_path, headers: true, header_converters: %i[downcase symbol]) do |row|
            val = row[typefield]
            next if mapped.any?(val)
            next if !migrate_no_val && no_val_pattern.match?(val)

            ids[row[idfield]] = val
          end
          ids
        end

        def inverted(result)
          inverted = {}
          result.reject{ |col, vals| vals.empty? }
            .each do |col, vals|
              vals.each do |val|
                inverted[val] = [] unless inverted.key?(val)
                inverted[val] << col
              end
            end
          inverted
        end

        def report_format(result)
          report = []
          inverted(result).each do |val, col|
            report << "#{mod}: `#{unmapped[val]}` (id: #{val}) used in: #{col.join(', ')}"
          end
          report
        end

        def setup_used_in
          cols = mod.used_in
          return nil if cols.empty?

          result = {}

          cols.each do |col|
            val = col.split('.')
            path = Tms::Table::Obj.new(val[0]).supplied_data_path
            field = val[1].to_sym
            result[col] = [path, field]
          end

          result
        end

        def unmapped_values
          value_getter.call
            .map{ |col, vals| [col, vals.select{ |val| unmapped.key?(val) }] }.to_h
        end
      end
    end
  end
end
