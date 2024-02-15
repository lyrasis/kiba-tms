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
        class ForObjectsPrepper
          def initialize
            @sources = %i[constatement remarks datebegin dateend]
            @targets = %i[note]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: sources
            )
            @namegetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: %i[person org]
            )
            @assoc_roles = get_assoc_roles
            @owner_roles = get_owner_roles
          end

          def process(row)
            targets.each { |target| row[target] = nil }
            preprocess(row)
            build_note(row)
            postprocess(row)

            row
          end

          private

          attr_reader :sources, :targets, :getter, :namegetter, :assoc_roles,
            :owner_roles

          def build_note(row)
            vals = getter.call(row)
            return row if vals.empty?

            dates = build_datestring(vals)
            role = row[:role]
            prefix = note_prefix(row, role)
            row[target(row, role)] = [prefix, dates, note(vals)].flatten
              .compact
              .join(": ")
          end

          # Redefine in subclass for more complex logic
          def target(row, role) = :note

          def build_datestring(vals)
            fields = %i[datebegin dateend]
            return if vals.keys.none? { |key| fields.include?(key) }

            datevals = fields.map { |field| vals[field] }.compact

            case datevals.length
            when 1
              datevals.first
            when 2
              datevals.join("-")
            end
          end

          def note_prefix(row, role)
            return nil unless note_prefixable?(row, role)
            name = namegetter.call(row)
              .values
              .first

            "RE: #{name} (#{role})"
          end

          # Redefine in subclass for more complex logic
          def note_prefixable?(row, role)
            true unless assoc_roles.include?(role)
          end

          def note(vals)
            fields = %i[constatement remarks]
            return nil if vals.keys.intersection(fields).empty?

            fields.map { |field| vals[field] }
              .compact
          end

          def get_assoc_roles
            return [] unless Kiba::Tms::Objects.con_ref_role_to_field_mapping
              .key?(:assoc)

            Kiba::Tms::Objects.con_ref_role_to_field_mapping[:assoc]
          end

          def get_owner_roles
            return [] unless Kiba::Tms::Objects.con_ref_role_to_field_mapping
              .key?(:owner)

            Kiba::Tms::Objects.con_ref_role_to_field_mapping[:owner]
          end

          def postprocess(row)
            # Define in project-specific subclass
          end

          def preprocess(row)
            # Define in project-specific subclass
          end
        end
      end
    end
  end
end
