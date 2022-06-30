# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class NonTextInscriptionCombiner < AbstractInscriptionCombiner
          def initialize
            @sources = Tms.objects.nontext_inscription_source_fields
            @targets = Tms.objects.nontext_inscription_target_fields
          end
        end
      end
    end
  end
end
