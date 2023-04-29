# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConRefs
        # Combines remarks and constatement fields into note field, and
        #   generates a prefix for notes that are not mapped to fields directly
        #   associated with an individual name
        #
        # NOTE that this is designed a little oddly so that it can be
        #   subclassed by client-specific transforms easily
        class ForObjects
          def initialize
            @sources = %i[constatement remarks]
            @targets = %i[note]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: sources
            )
            @namegetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: %i[person org]
            )
            @assoc_roles = get_assoc_roles
          end

          def process(row)
            targets.each{ |target| row[target] = nil }
            preprocess(row)
            build_note(row)
            postprocess(row)

            row
          end

          private

          attr_reader :sources, :targets, :getter, :namegetter, :assoc_roles

          def build_note(row)
            vals = getter.call(row).values
            return row if vals.empty?

            prefix = note_prefix(row)
            row[:note] = [prefix, vals].flatten
              .compact
              .join(": ")
          end

          def note_prefix(row)
            name = namegetter.call(row)
              .values
              .first
            role = row[:role]

            if assoc_roles.any?(role)
              nil
            else
              "RE: #{name} (#{role})"
            end
          end

          def get_assoc_roles
            if Kiba::Tms::Objects.con_ref_role_to_field_mapping.key?(:assoc)
              Kiba::Tms::Objects.con_ref_role_to_field_mapping[:assoc]
            else
              []
            end
          end

          def postprocess(row)
          end

          def preprocess(row)
          end
        end
      end
    end
  end
end
