# frozen_string_literal: true

module Kiba
  module Tms
    module ConceptAssociated
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] full keys of jobs that compile works
      #   values from separate sources. Each job should set the
      #   unnormalized term value in :termpreferred field. Optionally,
      #   other term field values can be set. Rows in source jobs should
      #   NOT be deduplicated, because the compilation job will
      #   normalize to the most frequently used form of each term.
      setting :compile_sources,
        default: [],
        reader: true

      # Client-project-specific cleaners of terms extracted for authority.
      #   Specify so it can be passed to Tms::Transforms::List
      setting :term_cleaners, default: [], reader: true
    end
  end
end
