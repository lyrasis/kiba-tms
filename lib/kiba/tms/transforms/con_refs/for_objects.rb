# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConRefs
        # Combines remarks and constatement fields into note field
        class ForObjects
          def initialize
            @sources = %i[constatement remarks]
            @target = :note
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: sources
            )
            @namegetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: %i[person org]
            )
            @assoc_roles = get_assoc_roles
          end

          def process(row)
            row[target] = nil
            vals = getter.call(row).values
            return row if vals.empty?

            prefix = note_prefix(row)
            row[target] = [prefix, vals].flatten
              .compact
              .join(': ')
            row
          end

          private

          attr_reader :sources, :target, :getter, :namegetter, :assoc_roles

          def note_prefix(row)
            name = namegetter.call(row)
              .values
              .first
            role = row[:role]

            if assoc_roles.any?(role)
              nil
            else
              "#{name} (#{role})"
            end
          end

          def get_assoc_roles
            if Kiba::Tms::Objects.con_ref_role_to_field_mapping.key?(:assoc)
              Kiba::Tms::Objects.con_ref_role_to_field_mapping[:assoc]
            else
              []
            end
          end
        end
      end
    end
  end
end
