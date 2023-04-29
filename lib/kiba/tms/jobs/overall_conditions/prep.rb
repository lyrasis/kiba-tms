# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OverallConditions
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__overall_conditions,
                destination: :prep__overall_conditions
              },
              transformer: config.multitable_xforms(binding)
            )
          end
        end
      end
    end
  end
end
