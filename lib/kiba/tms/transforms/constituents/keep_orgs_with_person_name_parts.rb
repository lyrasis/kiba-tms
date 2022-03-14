# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        # Creates :contact_person_displayname and contact_person_alphasort fields using
        #   name part fields 
        class KeepOrgsWithPersonNameParts
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
          end

          # @private
          def process(row)
            type = row.fetch(:constituenttype, nil)
            return unless type == 'Organization'
            
            vals = field_values(row: row, fields: %i[lastname firstname nametitle middlename suffix salutation])
            return if vals.empty?
                                
            row
          end
        end
      end
    end
  end
end
