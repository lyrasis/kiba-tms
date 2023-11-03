# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsTreatmentMergerDeathDissolutionPlace < GroupedFieldExtract
          def initialize
            @target_base = "term_death_dissolution_place_"
            @source_mapping = {
              termpreferred: "preferred",
              termused: "used",
              remarks: "note"
            }
          end
        end
      end
    end
  end
end
