# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Objectnumber2
          include Tms::Transforms::ValueAppendable

          def initialize
            @source = :objectnumber2
            @targettypefield = :othernumber_type
            @targettype = Tms::Objects.objectnumber2_type
            @targetvalfield = :othernumber_value
            @append_targets_set = false
            @append_targets = false
          end

          def process(row)
            set_append_targets(row) unless append_targets_set
            append_target_fields(row) if append_targets
            val = row[source]
            row.delete(source)
            return row if val.blank? || in_target?(row, val)

            append_value(row, targetvalfield, val, Tms.delim)
            append_value(row, targettypefield, targettype, Tms.delim)
            row
          end

          private

          attr_reader :source, :targettypefield, :targettype, :targetvalfield,
            :append_targets_set, :append_targets

          def set_append_targets(row)
            @append_targets_set = true
            @append_targets = true if row.keys.none?(targettypefield) ||
              row.keys.none?(targetvalfield)
          end

          def append_target_fields(row)
            [targetvalfield, targettypefield].each do |field|
              next if row.keys.any?(field)

              row[field] = nil
            end
          end

          def in_target?(row, val)
            targetvals(row).include?(val)
          end

          def targetvals(row)
            val = row[targetvalfield]
            return [] if val.blank?

            val.split(Tms.delim)
          end
        end
      end
    end
  end
end
