# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectConOrgsWithNameParts
          def initialize
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[
              firstname middlename lastname
            ])
          end

          # @private
          def process(row)
            @contype = ""
            @parts = {}

            return unless eligible?(row)

            row
          end

          private

          attr_reader :getter, :contype, :parts

          def data_eligible?(row)
            position = row[:position]
            return true if parts.length == 1 && !position.blank?

            true if parts.length > 1
          end

          def eligible?(row)
            type_eligible?(row) && parts_eligible?(row) && data_eligible?(row)
          end

          def parts_eligible?(row)
            @parts = getter.call(row)
            true unless parts.empty?
          end

          def type_eligible?(row)
            @contype = row[:contype]
            return false if contype.blank?

            true if contype["Organization"]
          end
        end
      end
    end
  end
end
