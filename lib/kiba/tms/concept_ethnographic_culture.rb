# frozen_string_literal: true

module Kiba
  module Tms
    module ConceptEthnographicCulture
      extend Dry::Configurable

      module_function

      def used?
        return false unless %i[anthro fcart].include?(Tms.cspace_profile)

        true unless compile_sources.empty?
      end

      # @return [Array<Symbol>] Fields from which dynamically generated
      #   compile_sources will be generated
      setting :compile_fields,
        default: %i[],
        reader: true,
        constructor: ->(_x) do
          case Tms.cspace_profile
          when :anthro
            warn("WARNING: Implement "\
                 "ConceptEthnographicCulture.compile_sources")
            %i[]
          when :fcart
            [Tms::Objects.assoceventpeople_sources,
              Tms::Objects.assocpeople_sources,
              Tms::Objects.contentpeople_sources].flatten
              .uniq
          end
        end

      # @return [Array<Symbol>] full keys of jobs that compile term
      #   values from separate sources. Each job should set the
      #   unnormalized term value in :culture field. Optionally,
      #   other term field values can be set. Rows in source jobs should
      #   NOT be deduplicated, because the compilation job will
      #   normalize to the most frequently used form of each term.
      setting :compile_sources,
        default: %i[],
        reader: true,
        constructor: ->(_x) do
                       compile_fields.map do |field|
                         "concept_ethnographic_culture__from_#{field}".to_sym
                       end
                     end
    end
  end
end
