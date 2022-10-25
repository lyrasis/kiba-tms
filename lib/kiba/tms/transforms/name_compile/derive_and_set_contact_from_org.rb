# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DeriveAndSetContactFromOrg
          include Derivable

          # @param mode [:alt, :main]
          # @param person_name_from [:nameparts, Symbol]
          def initialize(mode:, person_name_from:)
            @mode = mode
            @person_name_from = person_name_from
            @namefield = Tms::Constituents.preferred_name_field
            @personbuilder = Tms::Services::Constituents::PersonFromNameParts.new
            @contactadder = Tms::Transforms::NameCompile::AddRelatedTermAndRole.new(
              target: 'contact_person',
              maintype: 'Organization',
              mainnamefield: mode == :alt ? :conname : namefield,
              relnamefield: person_name_from == :nameparts ? :personname : person_name_from,
              rolefield: :position
            )
          end

          # @private
          def process(row)
            return nil if row[namefield] == 'DROPPED FROM MIGRATION'

            row[:personname] = personbuilder.call(row)
            build_rows(row).each{ |row| yield row }
            nil
          end

          private

          attr_reader :mode, :namefield, :personbuilder, :contactadder

          def add_shared_fields(row, fields)
            (fields - row.keys).each{ |field| row[field] = nil }
            row
          end

          def build_rows(row)
            initial = [
              derive_main_person(row.dup, :personname, mode),
              contactadder.process(row.dup)
            ]
            initial.each{ |irow| irow.delete(:personname) }
            fields = initial.map{ |irow| irow.keys }.flatten.uniq
            initial.map{ |irow| add_shared_fields(irow, fields) }
          end
        end
      end
    end
  end
end
