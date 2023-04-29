# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionTypes
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimension_types,
                destination: :prep__dimension_types
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
