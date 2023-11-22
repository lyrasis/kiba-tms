# frozen_string_literal: true

module Kiba
  module Tms
    module ConceptMaterial
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] full keys of jobs that compile works
      #   values from separate sources. Each job should set the
      #   unnormalized work term value in :material field. Optionally,
      #   other term field values can be set. Rows in source jobs should
      #   NOT be deduplicated, because the compilation job will
      #   normalize to the most frequently used form of each term.
      setting :compile_sources,
        default: [],
        reader: true,
        constructor: ->(_base) do
          Tms::Objects.material_controlled_source_fields.map do |type|
            "concept_material__from_#{type}".to_sym
          end
        end
    end
  end
end
