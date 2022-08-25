# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectConOrgsWithSingleNamePartNoPosition
          def initialize
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[firstname middlename lastname])
          end

          # @private
          def process(row)
            contype = row[:contype]
            return if contype.blank?
            return unless  contype['Organization']
            
            nameparts = getter.call(row)
            return unless nameparts.length == 1
            return unless row[:position].blank?

            row
          end
          
          private

          attr_reader :getter
        end
      end
    end
  end
end
