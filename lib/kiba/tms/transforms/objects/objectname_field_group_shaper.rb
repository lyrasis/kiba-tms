# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        # Renames name-value containing `namefield` to the correct basename,
        #   depending on whether it is controlled or not. Pads all other
        #   field group fields to the number of values in namefield.
        class ObjectnameFieldGroupShaper
          # @param prefix [Symbol] field name prefix for field group. Should
          #   match a value in Tms::Objects.objectname_source_fields
          # @param existing [Array<Symbol>] base fields already created. The
          #   created fields should already have the prefix, but don't use the
          #   prefix in this parameter
          # @param namefield [Symbol] base name of field containing the actual
          #   objectname name values
          def initialize(prefix:, existing: [], namefield: :objectname)
            @prefix = prefix
            @namefield = "#{prefix}_#{namefield}".to_sym
            namebase = Tms::Objects.objectname_base_for(prefix)
            @nametarget = "#{prefix}_#{namebase}".to_sym
            @notetarget = "#{prefix}_objectnamenote".to_sym
            bases = Tms::Objects.objectname_target_fields - [namebase]
            padfields = bases - existing
            @padfields = padfields.map { |field| "#{prefix}_#{field}".to_sym }
            @uncertainty_patterns =
              Tms::Objects.objectname_uncertainty_patterns
          end

          def process(row)
            val = row[namefield]
            row[nametarget] = val
            if val.blank?
              padfields.each { |field| row[field] = nil }
            else
              pad(row, val)
              note_uncertainties(row, val) unless uncertainty_patterns.empty?
              strip_name(row)
            end
            row.delete(namefield)
            row
          end

          private

          attr_reader :prefix, :namefield, :nametarget, :notetarget, :padfields,
            :uncertainty_patterns

          def pad(row, val)
            num = val.split(Tms.delim, -1).length
            padfields.each do |field|
              row[field] = Array.new(num, "%NULLVALUE%").join(Tms.delim)
            end
          end

          def note_uncertainties(row, val)
            return if val.blank?

            vals = val.split(Tms.delim, -1)
            notes = row[notetarget].split(Tms.delim, -1)
            vals.each_with_index do |name, idx|
              next unless uncertain?(name)

              note_uncertainty(name, idx, vals, notes)
            end

            row[nametarget] = vals.join(Tms.delim)
            row[notetarget] = notes.join(Tms.delim)
          end

          def strip_name(row)
            val = row[nametarget]
            row[nametarget] = val.split(Tms.delim, -1)
              .map(&:strip)
              .join(Tms.delim)
          end

          def note_uncertainty(name, idx, vals, notes)
            vals[idx] = name.gsub(uncertainty_pattern(name), "")
            note = notes[idx]
            noteval = if note == "%NULLVALUE%"
              "uncertain"
            else
              "#{note}; uncertain"
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
