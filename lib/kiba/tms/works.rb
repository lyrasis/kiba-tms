# frozen_string_literal: true

module Kiba
  module Tms
    module Works
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] full keys of jobs that compile works
      #   values from separate sources. Each job should set the
      #   unnormalized work term value in :work field. Optionally,
      #   :worktype and :termsource values can be set. These should
      #   NOT be deduplicated, because the compilation job will
      #   normalize to the most frequently used form of each term.
      setting :compile_sources,
        default: [],
        reader: true
    end
  end
end
