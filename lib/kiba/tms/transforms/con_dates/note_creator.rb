# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # creates a date-related note field for merge into person/org records
        class NoteCreator
          def initialize
            @target = :datenote_created
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[remarks date])
            @bdgetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[datedescription remarks date])
          end

          # @private
          def process(row)
            row[target] = nil
            
            type = row[:datedescription]
            if type == 'active'
              add_active_note(row)
            elsif type == 'birth' || type == 'death'
              add_birth_death_note(row)
            else
              add_other_note(row)
            end
            row
          end
          
          private

          attr_reader :target, :getter, :bdgetter

          def add_active_note(row)
            vals = getter.call(row)
            return if vals.empty?
            
            simple_active?(vals) ? add_simple_active_note(row, vals) : add_complex_active_note(row, vals)
          end
          
          def add_birth_death_note(row)
            duplicate = row[:duplicate_subsequent]
            if duplicate && duplicate == 'y'
              add_duplicate_birth_death_date_note(row)
            else
              remarks = row[:remarks]
              return if remarks.blank?

              type = row[:datedescription]
              row[target] = ["#{type} note", remarks].join(': ')
            end
          end

          def add_duplicate_birth_death_date_note(row)
            vals = bdgetter.call(row)
            return if vals.empty?

            if vals.key?(:remarks)
              base = ["Additional #{vals[:datedescription]} date", vals[:date]].join(': ')
              row[target] = "#{base} (#{vals[:remarks]})"
            else
              row[target] = ["Additional #{vals[:datedescription]} date", vals[:date]].join(': ')
            end
          end
            
          def add_other_note(row)
            vals = getter.call(row)
            return if vals.empty?
            
            row[target] = [other_label(row, vals), vals[:date]].compact.join(': ')
          end

          def add_complex_active_note(row, vals)
            if vals.key?(:date)
              base = simple_active_note(row, vals)
              noteval = "#{base} (#{vals[:remarks]})"
            else
              noteval = ['active', vals[:remarks]].join(' ')
            end
            row[target] = noteval
          end

          def add_simple_active_note(row, vals)
            row[target] = simple_active_note(row, vals)
          end

          def other_label(row, vals)
            [row[:datedescription], vals[:remarks]].compact.join(', ')
          end
          
          def simple_active?(vals)
            return false if vals.key?(:remarks)
            return false unless vals.key?(:date)

            true
          end

          def simple_active_note(row, vals)
            ['active', vals[:date]].join(' ')
          end
        end
      end
    end
  end
end
