# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TreatmentPriorities
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__treatment_priorities,
                destination: :prep__treatment_priorities
              },
              transformer: config.multitable_xforms(binding)
            )
          end
        end
      end
    end
  end
end
