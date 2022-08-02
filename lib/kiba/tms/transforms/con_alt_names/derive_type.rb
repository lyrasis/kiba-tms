# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAltNames
        class DeriveType
          def initialize
            @pgetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[lastname firstname])
            @ogetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: [:institution])
            @ochecker = Tms::Services::Names::OrgNameChecker.new(field: Tms::Constituents.preferred_name_field)
            @target = :altnametype
          end

          def process(row)
            row[target] = nil
            
            p_name = pgetter.call(row)
            o_name = ogetter.call(row)

            if p_name.empty? && o_name.empty?
              row[target] = 'Organization' if ochecker.call(row)
            elsif !p_name.empty? && !o_name.empty?
              row[target] = 'Organization' if ochecker.call(row)
            elsif !p_name.empty?
              row[target] = 'Person' unless p_name.empty?
            else
              row[target] = 'Organization' if p_name.empty?
            end
            row
          end

          private

          attr_reader :pgetter, :ogetter, :ochecker, :target
        end
      end
    end
  end
end
