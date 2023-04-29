# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DeriveOrgWithContactFromPerson
          include Derivable

          def initialize(mode:)
            @mode = mode
            @orgnamefield = (mode == :main) ? :institution : :altname
            @personnamefield = (mode == :main) ? Tms::Constituents.preferred_name_field : :conname
            @contactadder = Tms::Transforms::NameCompile::AddRelatedTermAndRole.new(
              target: "contact_person",
              maintype: "Organization",
              mainnamefield: orgnamefield,
              relnamefield: personnamefield,
              rolefield: :position
            )
          end

          # @private
          def process(row)
            build_rows(row).each { |row| yield row }
            nil
          end

          private

          attr_reader :mode, :orgnamefield, :personnamefield, :contactadder

          def add_shared_fields(row, fields)
            (fields - row.keys).each { |field| row[field] = nil }
            row
          end

          def build_rows(row)
            initial = [
              derive_main_org(row.dup, orgnamefield, mode),
              contactadder.process(row.dup)
            ]
            fields = initial.map { |irow| irow.keys }.flatten.uniq
            initial.map { |irow| add_shared_fields(irow, fields) }
          end
        end
      end
    end
  end
end
