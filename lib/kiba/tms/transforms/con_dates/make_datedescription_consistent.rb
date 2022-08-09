# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Cleans up variant values in datedescription
        class MakeDatedescriptionConsistent
          def initialize
            @cleaners = Tms::Constituents.dates.datedescription_variants
              .transform_values{ |val| "^ *(#{val.join('|')}) *$" }
              .map do |type, variants|
                Clean::RegexpFindReplaceFieldVals.new(
                  fields: :datedescription,
                  find: variants,
                  replace: type,
                  casesensitive: false
                )
              end
          end

          # @private
          def process(row)
            cleaners.each{ |cleaner| cleaner.process(row) }
            row
          end
          
          private

          attr_reader :cleaners
        end
      end
    end
  end
end
