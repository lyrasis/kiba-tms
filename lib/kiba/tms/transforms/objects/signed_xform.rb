# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class SignedXform < TextInscriptionXform
          def initialize
            @source = :signed
            @typeval = 'signature'
          end
        end
      end
    end
  end
end
