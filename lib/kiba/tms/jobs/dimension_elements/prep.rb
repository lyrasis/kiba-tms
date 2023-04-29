# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionElements
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimension_elements,
                destination: :prep__dimension_elements
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
