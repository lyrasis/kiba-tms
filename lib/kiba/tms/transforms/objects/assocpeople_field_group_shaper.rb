# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class AssocpeopleFieldGroupShaper
          # @param source [Array<Symbol>] field name from which
          #   field group will be shaped. Should match a value in
          #   Tms::Objects.assocpeople_source_fields
          # @param type [Nil, String]
          def initialize(source:, type: nil)
            @source = source
            bases = %i[assocpeople assocpeopletype assocpeoplenote]
            targets = bases.map { |base| "#{source}_#{base}".to_sym }
            @target = targets[0]
            @notetarget = targets[2]
            @typetarget = targets[1]
            @typeval = type
            @uncertainty_patterns =
              Tms::Objects.ethculture_uncertainty_patterns
          end

          def process(row)
            val = row[source]
            row[target] = val
            pad(row, val)
            note_uncertainties(row, val) unless uncertainty_patterns.empty?
            strip_target(row)
            row.delete(source)
            row
          end

          private

          attr_reader :source, :target, :notetarget, :typetarget, :typeval,
            :uncertainty_patterns

          def pad(row, val)
            [notetarget, typetarget].each { |field| append(field, row) }
            return if val.blank?

            num = val.split(Tms.delim, -1).length
            pad_type(row, num)
            pad_note(row, num)
          end

          def note_uncertainties(row, val)
            return if val.blank?

            vals = val.split(Tms.delim, -1)
            notes = row[notetarget].split(Tms.delim, -1)
            vals.each_with_index do |name, idx|
              next unless uncertain?(name)

              note_uncertainty(name, idx, vals, notes)
            end

            row[target] = vals.join(Tms.delim)
            row[notetarget] = notes.join(Tms.delim)
          end

          def strip_target(row)
            val = row[target]
            return if val.blank?

            row[target] = val.split(Tms.delim, -1)
              .map(&:strip)
              .join(Tms.delim)
          end

          def note_uncertainty(name, idx, vals, notes)
            orig = vals[idx].dup
            vals[idx] = name.gsub(uncertainty_pattern(name), " ")
              .gsub(/  +/, " ")
              .strip
            note = notes[idx]
            notetext = "uncertain [orig value: #{orig}]"
            noteval = if note == "%NULLVALUE%"
              notetext
            else
              "#{note}; #{notetext}"
            end
            notes[idx] = noteval
          end

          def append(field, row)
            return if row.key?(field)

            row[field] = nil
          end

          def pad_type(row, num)
            val = row[typetarget]
            if val.blank?
              row[typetarget] = Array.new(num, typeval).join(Tms.delim)
            else
              pad_existing(row, num, typetarget, val, typeval)
            end
          end

          def pad_note(row, num)
            val = row[notetarget]
            if val.blank?
              row[notetarget] = Array.new(num, "%NULLVALUE%").join(Tms.delim)
            else
              pad_existing(row, num, notetarget, val, "%NULLVALUE%")
            end
          end

          def pad_existing(row, num, target, current, padval)
            vals = current.split(Tms.delim, -1)
            val_len = vals.length
            return if val_len == num

            if val_len < num
              diff = num - val_len
              diff.times { vals << padval }
            else
              until vals.length == num
                vals.pop
              end
            end
            row[target] = vals.join(Tms.delim)
          end

          def uncertain?(value)
            uncertainty_patterns.any? { |re| value.match?(re) }
          end

          def uncertainty_pattern(value)
            uncertainty_patterns.select { |re| value.match?(re) }
              .first
          end
        end
      end
    end
  end
end
