# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # If one birth date row has "1975" and another has "1975 Aug 06", will remove the row with just "1975"
        class ReducePartialDuplicates
          def initialize
            @groupfield = :combined
            @valuefield = :date
            @eligible_types = Tms::Constituents.dates.known_types
            @data = {}
            @rows = []
          end

          def process(row)
            group = row[groupfield]
            populate_data(group, row)
            nil
          end

          def close
            data.each{ |group, gdata| collect_rows(gdata) }
            rows.each{ |row| yield row }
          end
          
          private

          attr_reader :groupfield, :valuefield, :eligible_types, :data, :rows

          def add_new_group(group, row)
            eligible?(row) ? data[group] = {} : data[group] = []
            add_row_to_group(group, row)
          end
          
          def add_row_to_group(group, row)
            if eligible?(row)
              data[group][row[valuefield]] = row
            else
              data[group] << row
            end
          end
          
          def collect_rows(group)
            if group.is_a?(Array)
              group.each{ |row| rows << row }
            else
              group.length == 1 ? collect_single_hash_row(group) : collect_reduced_hash_rows(group)  
            end
          end

          # keeps the order of rows/values
          def collect_reduced_hash_rows(group)
            keeping = retained_keys(group)
            group.select{ |key, value| keeping.any?(key) }
              .each{ |_key, val| rows << val }
          end

          def collect_single_hash_row(group)
            rows << group.values.first
          end
          
          def eligible?(row)
            type = row[:datedescription]
            return false if type.blank?

            eligible_types.any?(type)
          end

          def populate_data(group, row)
            data.key?(group) ? add_row_to_group(group, row) : add_new_group(group, row)
          end

          def retained_keys(group)
            retain = []
            retain << nil if group.keys.any?(&:nil?)
            
            keys = group.keys.compact.sort_by{ |key| key.length }
            until keys.empty?
              thiskey = keys.shift
              retain << thiskey unless keys.any?{ |key| key[thiskey] }
            end
            retain
          end
        end
      end
    end
  end
end
