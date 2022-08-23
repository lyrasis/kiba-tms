# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Loansin
        class DisplayDateNote
          def initialize(target:)
            @target = target
            @sources = %i[dispbegisodate dispendisodate]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: sources)
            @note_prefix = Tms::Loansin.display_date_note_label
          end

          def process(row)
            row[target] = nil
            vals = getter.call(row)
            sources.each{ |field| row.delete(field) }
            return row if vals.empty?

            if vals.length == 2
              row[target] = "#{note_prefix}#{vals.values.join(' - ')}"
            elsif vals.key?(:dispbegisodate)
              row[target] = "#{note_prefix}#{vals[:dispbegisodate]} -"
            else
              row[target] = "#{note_prefix}- #{vals[:dispendisodate]}"
            end
            row
          end

          private

          attr_reader :target, :sources, :getter, :note_prefix
        end
      end
    end
  end
end
