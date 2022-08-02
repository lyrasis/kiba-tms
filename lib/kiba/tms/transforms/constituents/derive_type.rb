# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class DeriveType
          def initialize
            @type = :constituenttype
            @pgetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[lastname firstname])
            @ogetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: [:institution])
            @target = :derivedcontype
          end

          def process(row)
            row[target] = nil
            typeval = row[type]
            return row unless typeval.blank?
            
            p_name = pgetter.call(row)
            o_name = ogetter.call(row)
            return row if p_name.empty? && o_name.empty?
            return row if !p_name.empty? && !o_name.empty?

            row[target] = 'Person' unless p_name.empty?
            row[target] = 'Organization' if p_name.empty?

            row
          end

          private

          attr_reader :type, :pgetter, :ogetter, :target
        end
      end
    end
  end
end
