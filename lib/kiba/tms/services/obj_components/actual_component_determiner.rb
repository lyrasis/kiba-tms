# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Services
      module ObjComponents
        class ActualComponentDeterminer
          def self.call(...)
            self.new(...).call
          end
          
          def initialize
            @mod = Tms::ObjComponents
            @path = mod.table.supplied_data_path
            @acc = {}
          end

          def call
            return nil unless mod.used?
            return nil unless path

            accumulate_values
            multi_row = acc.reject{ |_key, val| val == 1 }
            multi_row.empty? ? false : true
          end

          private

          attr_reader :mod, :path, :acc
          
          def accumulate_values
            CSV.foreach(path, headers: true, header_converters: %i[downcase symbol]) do |row|
              obj = row[:objectid]
              acc[obj] = 0 unless acc.key?(obj)
              acc[obj] += 1
            end
          end
        end
      end
    end
  end
end
