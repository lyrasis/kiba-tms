# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class MaterialFieldGroupShaper
          # @param source [Symbol] field name from which field group will be
          #   shaped. Should match a value in
          #   Tms::Objects.material_source_fields
          # @param component [String] value used in :materialcomponent field
          def initialize(source:, component:)
            @source = source
            bases = [Tms::Objects.material_base_for(source),
              :materialcomponentnote,
              :materialcomponent]
            targets = bases.map { |base| "#{source}_#{base}".to_sym }
            @target = targets[0]
            @notetarget = targets[1]
            @comptarget = targets[2]
            @compval = component
            padfields = Tms::Objects.material_target_fields - bases
            @padfields = padfields.map { |field| "#{source}_#{field}".to_sym }
            @is_note = Tms::Objects.material_is_note
            @uncertainty_patterns =
              Tms::Objects.material_uncertainty_patterns
          end

          def process(row)
            move_notes(row)
            pad(row)
            note_uncertainties(row) unless uncertainty_patterns.empty?
            strip_target(row)
            row.delete(source)
            row
          end

          private

          attr_reader :source, :target, :notetarget, :comptarget, :compval,
            :padfields, :is_note, :uncertainty_patterns

          def move_notes(row)
            row[target] = nil
            row[notetarget] = nil
            row[comptarget] = nil
            val = row[source]
            return if val.blank?

            compvals = []
            matvals = []
            notevals = []
            val.split(Tms.delim).each do |value|
              compvals << compval
              if is_note.call(value)
                matvals << "%NULLVALUE%"
                notevals << value
              else
                matvals << value
                notevals << "%NULLVALUE%"
              end
            end

            row[target] = matvals.join(Tms.delim)
            row[notetarget] = notevals.join(Tms.delim)
            row[comptarget] = compvals.join(Tms.delim)
          end

          def pad(row)
            padfields.each { |field| row[field] = nil }
            val = row[target]
            return if val.blank?

            num = val.split(Tms.delim).length
            padfields.each do |field|
              row[field] = Array.new(num, "%NULLVALUE%").join(Tms.delim)
            end
          end

          def note_uncertainties(row)
            val = row[target]
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
