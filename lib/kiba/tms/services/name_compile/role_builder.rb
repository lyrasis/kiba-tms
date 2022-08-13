# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module NameCompile
        # Returns Relator/Role value derived from :position, :institution, and, optionally,
        #   :altnametype values
        class RoleBuilder
          def initialize(include_nametype: true)
            @include_nametype = include_nametype
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[position institution])
          end

          def call(row)
            relator(row)
          end

          private

          attr_reader :getter, :include_nametype
          
          def from_position(row)
            vals = getter.call(row)
            return nil if vals.empty?

            vals.values.join(', ')
          end

          def from_type(row)
            return nil unless include_nametype
            
            type = row[:altnametype]
            return nil if type.blank?

            "#{type.downcase.delete_suffix(' name')} name"
          end
          
          def relator(row)
            position = from_position(row)
            position ? position : from_type(row)
          end
        end
      end
    end
  end
end
