# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        # Selects one person name from handler, approver, or requestedby
        #   names to assign as :inventorycontact or :movementcontact in CS
        class AssignContactPerson
          # @param target [:inventory, :movement] affects target contact field
          def initialize(target:)
            @target = "#{target}contact".to_sym
            @name_getter =
              Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
                fields: Tms::ObjLocations.contact_person_preference
              )
          end

          def process(row)
            names = name_getter.call(row)
            row[target] = if names.empty?
              nil
            else
              names.first[1]
            end
            row
          end

          private

          attr_reader :target, :name_getter
        end
      end
    end
  end
end
