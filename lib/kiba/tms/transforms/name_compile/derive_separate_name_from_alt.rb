# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DeriveSeparateNameFromAlt
          include Derivable
          include RowEvenable

          def initialize
            @rows = []
          end

          def process(row)
            type = row[:altauthtype]
            if type.blank?
              case Tms::Names.untyped_default
              when "Person" then person_row(row)
              when "Organization" then org_row(row)
              end
            else
              type.start_with?("Person") ? person_row(row) : org_row(row)
            end
            nil
          end

          private

          attr_reader :rows

          def org_row(row)
            rows << derive_main_org(row.dup, :altname, :alt)
          end

          def person_row(row)
            rows << derive_main_person(row.dup, :altname, :alt)
          end
        end
      end
    end
  end
end
