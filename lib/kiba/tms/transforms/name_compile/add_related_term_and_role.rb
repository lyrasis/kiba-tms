# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class AddRelatedTermAndRole
          def initialize(target:, maintype:, mainnamefield:, relnamefield:, rolefield: nil)
            @target = target
            @maintype = maintype
            @mainnamefield = mainnamefield
            @relnamefield = relnamefield
            @rolefield = ->(row){ row[:related_role] = row[rolefield] } if rolefield
            @namefield = Tms::Constituents.preferred_name_field
            @relbuilder = Tms::Services::NameCompile::RoleBuilder.new(include_nametype: false) unless rolefield
          end

          # @private
          def process(row)
            row[:related_term] = row[relnamefield]
            row[:contype] = maintype
            row[namefield] = row[mainnamefield]
            row[:relation_type] = target
            add_relator(row)
            [Tms::NameCompile.variant_nil, Tms::NameCompile.alt_nil].flatten.each{ |field| row.delete(field) }

            row
          end
          
          private

          attr_reader :target, :maintype, :mainnamefield, :relnamefield, :rolefield, :namefield, :relbuilder

          def add_relator(row)
            rolefield ? rolefield.call(row) : row[:related_role] = relbuilder.call(row)
          end
        end
      end
    end
  end
end
