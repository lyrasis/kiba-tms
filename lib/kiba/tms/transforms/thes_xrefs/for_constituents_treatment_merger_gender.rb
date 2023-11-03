# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsTreatmentMergerGender < GroupedFieldExtract
          def initialize
            @target_base = "term_gender_"
            @source_mapping = {
              thesxreftype: "label",
              termused: "",
              remarks: "note"
            }
          end
        end
      end
    end
  end
end
