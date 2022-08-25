# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class DeriveType
          # @param mode [:main, alt]
          def initialize(mode: :main)
            @mode = mode
            @type = :constituenttype
            @target = mainmode? ? :derivedcontype : :altauthtype
            @pgetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[lastname firstname])
            @ogetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: [:institution])
            @ochecker = Tms::Services::Names::OrgNameChecker.new(field: Tms::Constituents.preferred_name_field)
          end

          def process(row)
            row[target] = nil

            if mainmode?
              typeval = row[type]
              return row unless typeval.blank?
            end
            
            derived = derived_type(row)
            row[target] = derived if derived
            
            row
          end

          private

          attr_reader :mode, :type, :target, :pgetter, :ogetter, :ochecker

          def derived_type(row)
            p_name = pgetter.call(row)
            o_name = ogetter.call(row)

            if p_name.empty? && o_name.empty?
              'Organization' if ochecker.call(row)
            elsif !p_name.empty? && !o_name.empty?
              'Organization' if ochecker.call(row)
            elsif !p_name.empty?
              'Person' unless p_name.empty?
            else
              'Organization' if p_name.empty?
            end
          end
          
          def mainmode?
            mode == :main
          end
        end
      end
    end
  end
end
