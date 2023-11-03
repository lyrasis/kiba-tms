# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsTreatmentMergerBirthFoundingPlace < GroupedFieldExtract
          def initialize
            @target_base = "term_birth_founding_place_"
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
