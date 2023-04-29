# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        # Creates :contact_person_displayname and contact_person_alphasort fields using
        #   name part fields 
        class KeepOrgsWithPersonNameParts
          def initialize
            @fields = %i[lastname firstname nametitle middlename suffix salutation]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: fields)
          end

          # @private
          def process(row)
            type = row.fetch(:constituenttype, nil)
            return unless type == "Organization"
            
            vals = getter.call(row)
            return if vals.empty?
                                
            row
          end

          private

          attr_reader :fields, :getter
        end
      end
    end
  end
end
