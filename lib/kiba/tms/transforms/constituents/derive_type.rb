# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class DeriveType
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @person = %i[lastname firstname]
            @org = :institution
            @target = :derivedcontype
          end

          def process(row)
            row[@target] = nil
            p_name = field_values(row: row, fields: @person)
            o_name = field_values(row: row, fields: [@org])
            return row if p_name.empty? && o_name.empty?
            return row if !p_name.empty? && !o_name.empty?

            row[@target] = 'person' unless p_name.empty?
            row[@target] = 'organization' if p_name.empty?

            row
          end
        end
      end
    end
  end
end
