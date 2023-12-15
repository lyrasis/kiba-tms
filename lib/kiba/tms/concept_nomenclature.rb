# frozen_string_literal: true

module Kiba
  module Tms
    module ConceptNomenclature
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] full keys of jobs that compile works
      #   values from separate sources. Each job should set the
      #   unnormalized work term value in :term field. Optionally,
      #   other term field values can be set. Rows in source jobs should
      #   NOT be deduplicated, because the compilation job will
      #   normalize to the most frequently used form of each term.
      setting :compile_sources,
        default: [],
        reader: true,
        constructor: ->(base) do
          if Tms::Objects.objectnamecontrolled_source_fields.include?(:obj)
            base << :concept_nomenclature__from_objectname
          end
          if Tms::Objects.objectnamecontrolled_source_fields.include?(:on)
            base << :concept_nomenclature__from_object_names_table
          end
          base.flatten
        end
    end
  end
end
