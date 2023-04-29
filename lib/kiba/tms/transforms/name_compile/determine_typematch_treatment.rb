# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DetermineTypematchTreatment
          def initialize
            @target = :treatment
            @typefield = :altnametype
            @vartypes = Tms::NameCompile.altname_typematch_variant_nametypes
          end

          # @private
          def process(row)
            row[target] = determine_treatment(row)

            row
          end

          private

          attr_reader :target, :typefield, :vartypes

          def determine_treatment(row)
            type = row[typefield]
            return no_type_treatment(row) if type.blank?

            variant_type?(type) ? :variant : :separate_name
          end

          def no_type_treatment(row)
            return Tms::NameCompile.altname_typematch_no_nametype_no_position if row[:position].blank?

            Tms::NameCompile.altname_typematch_no_nametype_position
          end

          def variant_type?(type)
            lc = type.downcase
            vartypes.any? { |vartype| lc.start_with?(vartype) }
          end
        end
      end
    end
  end
end
