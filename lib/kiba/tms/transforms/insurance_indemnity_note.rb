# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class InsuranceIndemnityNote
        def initialize(target: :insind)
          @target = target
          @sources = %i[insurancefromlender insurancefrompreviousvenue
                        insuranceatvenue insurancereturn
                        indemnityfromlender indemnityfrompreviousvenue
                        indemnityatvenue indemnityreturn]
          @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
            fields: sources
          )
          @prefixes = {
            insurancefromlender: 'Insurance from lender',
            insurancefrompreviousvenue: 'Insurance from previous venue',
            insuranceatvenue: 'Insurance at venue',
            insurancereturn: 'Insurance return',
            indemnityfromlender: 'Indemnity from lender',
            indemnityfrompreviousvenue: 'Indemnity from previous venue',
            indemnityatvenue: 'Indemnity at venue',
            indemnityreturn: 'Indemnity return'
          }
        end

        def process(row)
          row[target] = nil
          vals = getter.call(row)
          sources.each{ |field| row.delete(field) }
          return row if vals.empty?

          row[target] = vals.map{ |field, val| "#{prefixes[field]}: #{val}" }
            .join('%CR%')
          row
        end

        private

        attr_reader :target, :sources, :getter, :prefixes
      end
    end
  end
end
