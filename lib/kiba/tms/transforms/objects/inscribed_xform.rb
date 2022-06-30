# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class InscribedXform < TextInscriptionXform
          def initialize
            @source = :inscribed
            @typeval = 'inscribed'
          end
        end
      end
    end
  end
end
