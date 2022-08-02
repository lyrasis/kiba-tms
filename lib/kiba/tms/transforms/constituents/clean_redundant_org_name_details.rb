# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class CleanRedundantOrgNameDetails
          def initialize
            @type_field = :constituenttype
            @name_field = Tms::Constituents.preferred_name_field
            @core_name_detail_fields = %i[firstname lastname middlename suffix]
            @addl_name_detail_fields = %i[nametitle salutation]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: core_name_detail_fields)
          end

          # @private
          def process(row)
            return row unless is_org(row)
            return row if has_position(row)
            return row unless redundant_details(row)

            clean(row)
            row
          end

          private

          attr_reader :type_field, :name_field, :core_name_detail_fields, :addl_name_detail_fields, :getter

          def clean(row)
            [core_name_detail_fields, addl_name_detail_fields].flatten
              .intersection(row.keys)
              .each{ |field| row[field] = nil }
          end

          def has_position(row)
            position = row[:position]
            true unless position.blank?
          end
          
          def is_org(row)
            type = row[type_field]
            return false if type.blank?

            true if type == 'Organization'
          end

          def redundant_details(row)
            nameval = row[name_field]
            return false if nameval.blank?

            details = getter.call(row)
            return false if details.empty?

            details.values.map(&:downcase).map{ |dval| nameval.downcase[dval] }.none?(nil)
          end
        end
      end
    end
  end
end
