# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class RenamePreferredNameField
          include Kiba::Extend::Transforms::Helpers

          # @param target [Symbol] new field name
          def initialize(target:)
            @name = Kiba::Tms.config.constituents.preferred_name_field
            @target = target
          end

          def process(row)
            name_val = row.fetch(name, nil)
            row[target] = name_val
            row.delete(name)
            row
          end

          private

          attr_reader :name, :target
        end
      end
    end
  end
end
