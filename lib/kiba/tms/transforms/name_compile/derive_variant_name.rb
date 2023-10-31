# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DeriveVariantName
          include RowEvenable
          # @param mode [:alt, :main] whether deriving from ConAltNames or
          #   Constituents row
          # @param from [:nil, :inst, :nameparts] only relevant for
          #   organizations, since we may want to derive either an
          #   organization or a person variant name from an
          #   organization. In a person row, deriving from name parts
          #   would result in the already-existing person name
          def initialize(mode:, from: nil)
            @mode = mode
            @from = from
            @authtypefield = (mode == :alt) ? :conauthtype : :contype
            @namefield = Tms::Constituents.preferred_name_field
            @relbuilder = Tms::Services::NameCompile::RoleBuilder.new
            @personbuilder = Tms::Services::Constituents::PersonFromNameParts.new
            @rows = []
          end

          # @private
          def process(row)
            @authtype = row[authtypefield]

            row[namefield] = row[:conname] if mode == :alt
            row[:contype] = authtype
            row[:relation_type] = "variant term"
            row[:variant_term] = variant_term(row)
            row[:variant_qualifier] = relbuilder.call(row)
            deletefields.each { |field| row.delete(field) }
            rows << row
            nil
          end

          private

          attr_reader :mode, :from, :authtypefield, :namefield, :relbuilder,
            :personbuilder, :authtype, :rows

          def deletefields
            todelete = if authtype == "Person"
              Tms::NameCompile.person_nil
            elsif authtype == "Organization"
              Tms::NameCompile.org_nil
            else
              []
            end

            todelete << Tms::NameCompile.derived_nil
            todelete << Tms::NameCompile.alt_nil if mode == :alt
            todelete.flatten.uniq
          end

          def variant_term(row)
            if mode == :main && authtype == "Organization" && from == :nameparts
              personbuilder.call(row)
            elsif from
              row[from]
            elsif mode == :main
              row[:institution]
            elsif mode == :alt
              row[:altname]
            end
          end
        end
      end
    end
  end
end
