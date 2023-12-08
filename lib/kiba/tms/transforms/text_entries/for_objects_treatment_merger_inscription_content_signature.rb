# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerInscriptionContentSignature <
            ForObjectsTreatmentMergerInscriptionContent
          def initialize
            super
            @typeval = "signature"
          end
        end
      end
    end
  end
end
