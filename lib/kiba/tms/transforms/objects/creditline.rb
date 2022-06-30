# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Creditline < Kiba::Extend::Transforms::Cspace::AbstractAnnotation
          def initialize
            @source = :creditline
            @type = 'Credit Line'
          end
        end
      end
    end
  end
end
