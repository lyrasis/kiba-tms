# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class TemptextMappings
          def initialize
            @mappingsrc = :ttmapping
            @correctsrc = :ttcorrect
            @targets = Tms::ObjLocations.temptext_target_fields +
              Tms::ObjLocations.temptext_note_targets
          end

          def process(row)
            targets.each{ |field| row[field] = nil }
            mapping = row[mappingsrc]
            correct = row[correctsrc]
            [mappingsrc, correctsrc, :lookupid].each{ |fld| row.delete(fld) }
            return row if mapping.blank?
            return row if mapping == 'drop'

            mapsym = mapping.to_sym
            if targets.none?(mapsym)
              fail(Tms::UnknownObjLocTempTextMappingError, mapsym)
            end

            val = correct.blank? ? row[:temptext] : correct
            row[mapsym] = val
            row
          end

          private

          attr_reader :mappingsrc, :correctsrc, :targets
        end
      end
    end
  end
end
