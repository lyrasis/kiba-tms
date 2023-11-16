# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForObjectsTreatmentMergerTermField < GroupedFieldExtract
          def initialize
            @target_base = "term_untyped_"
            @source_mapping = {
              termused: "used",
              termpreferred: "preferred",
              termsource: "source"
            }
          end
        end
      end
    end
  end
end
