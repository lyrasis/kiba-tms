# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Locations
        class AddLocationType
          def initialize
            @delim = Tms.locations.hierarchy_delim
            @target = :locationtype
          end

          def process(row)
            row[target] = nil

            locname = row.fetch(:location_name, nil)
            return row if locname.blank?

            loc = locname.split(delim)[-1].downcase

            if is_match?(%w[room office], loc)
              type = 'Room'
            elsif is_match?(%w[drawer], loc)
              type = 'Drawer'
            elsif is_match?(%w[shelf], loc)
              type = 'Shelf'
            elsif is_match?(%w[tray], loc)
              type = 'Tray'
            elsif is_match?(%w[box], loc)
              type = 'Box'
            elsif is_match?(%w[case], loc)
              type = 'Case'
            elsif is_match?(%w[unit], loc)
              type = 'Unit'
            end
            
            return row unless type

            row[target] = type
            row
          end

          private

          attr_reader :delim, :target

          # @param matchers [Array<String>]
          # @param loc [String]
          def is_match?(matchers, loc)
            matchers.each do |str|
              return true if loc.match?(/^#{str}(\d+| )| *#{str}\d*$/)
            end
            false	
          end
        end
      end
    end
  end
end
