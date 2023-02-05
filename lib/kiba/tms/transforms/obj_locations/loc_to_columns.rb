# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class LocToColumns
          def initialize(locsrc:, authsrc:, target:)
            @locsrc = locsrc
            @authsrc = authsrc
            @target = target
            @suffix_map = {
              'Local'=>'locationlocal',
              'Offsite'=>'locationoffsite',
              'Organization'=>'organizationlocal'
            }
            @suffixes = suffix_map.values
          end

          def process(row)
            suffixes.each do |suffix|
              row["#{target}#{suffix}".to_sym] = nil
            end
            loc = row[locsrc]
            row.delete(locsrc)
            auth = row[authsrc]
            row.delete(authsrc)
            return row if loc.blank?

            targetfield = "#{target}#{suffix_map[auth]}".to_sym
            row[targetfield] = loc
            row
          end

          private

          attr_reader :locsrc, :authsrc, :target, :suffix_map, :suffixes
        end
      end
    end
  end
end
