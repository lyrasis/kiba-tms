# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class ReshapeCleanedDates
          def initialize
            @newrowfields = {
              begindateiso: :date,
              enddateiso: :date,
              datenote: :datenote
            }
            @copydatafields = %i[constituentid condateid]
            @datedescriptionmap = {
              begindateiso: "birth",
              enddateiso: "death",
              datenote: nil
            }
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: newrowfields.keys)
          end

          def process(row)
            vals = getter.call(row)
            return nil if vals.empty?

            create_rows(row, vals).each { |newrow| yield newrow }
            nil
          end

          private

          attr_reader :newrowfields, :copydatafields, :datedescriptionmap,
            :getter

          def create_row(row, field, value)
            newrow = {newrowfields[field] => value,
                      :datedescription => datedescriptionmap[field]}
            (newrowfields[field] == :date) ? newrow[:datenote] =
                                               nil : newrow[:date] = nil
            copydatafields.each { |cdf| newrow[cdf] = row[cdf] }
            newrow
          end

          def create_rows(row, vals)
            vals.map { |field, value| create_row(row, field, value) }
          end
        end
      end
    end
  end
end
