# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAltNames
        class DeleteRedundantInstitutionValues
          def initialize
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[conname altname altconname])
          end

          def process(row)
            @institution = ''
            
            return row unless eligible?(row)
            
            di = institution.downcase
            return row unless getter.call(row).values.any?{ |val| val.downcase == di }

            row[:institution] = nil
            row
          end

          private

          attr_reader :getter, :institution

          def eligible?(row)
            @institution = row[:institution]
            true unless institution.blank?
          end
        end
      end
    end
  end
end
