# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class MarkingsTextXform < TextInscriptionXform
          def initialize
            @source = :markings
            @typeval = Tms.objects.source_xform.markings_type
          end
        end
      end
    end
  end
end
