# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class TextInscriptionCombiner < AbstractInscriptionCombiner
          def initialize
            @sources = Tms.objects.text_inscription_source_fields
            @targets = Tms.objects.text_inscription_target_fields
          end
        end
      end
    end
  end
end
