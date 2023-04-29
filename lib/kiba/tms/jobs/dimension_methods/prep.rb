# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionMethods
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimension_methods,
                destination: :prep__dimension_methods
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
