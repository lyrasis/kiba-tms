# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class CleanOrgNameInfoFromPerson
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
          end

          # @private
          def process(row)
            type = row.fetch(:constituenttype, nil)
            return row unless type == 'Person'

            %i[institution contact_person].each do |field|
              row[field] = nil
            end
          
            row
          end
        end
      end
    end
  end
end
