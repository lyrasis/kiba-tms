# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAltNames
        # Qualifies alt name values that are considered anonymous by adding the
        #   main name as a parenthetical to the alt name
        class QualifyAnonymous
          def initialize
            @anon = Tms::ConAltNames.consider_anonymous.map(&:downcase)
            @pref = Tms::Constituents.preferred_name_field
            @mainname = :conname
          end

          def process(row)
            @altname = ''
            return row unless eligible?(row)

            qualify(row)
            row
          end

          private

          attr_reader :anon, :pref, :mainname, :altname

          def eligible?(row)
            @altname = row[pref]
            return false if altname.blank?

            anon.any?(altname.downcase)
          end

          def qualify(row)
            qualifier = row[mainname]
            return if qualifier.blank?

            row[pref] = "#{altname} (#{qualifier})"
          end
        end
      end
    end
  end
end
