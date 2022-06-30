# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class AnnotationCombiner < Kiba::Extend::Transforms::Cspace::AbstractFieldGroupCombiner
          def initialize
            @sources = Tms.objects.annotation_source_fields
            @targets = Tms.objects.annotation_target_fields
          end
        end
      end
    end
  end
end
