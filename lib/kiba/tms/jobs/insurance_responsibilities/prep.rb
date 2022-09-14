# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module InsuranceResponsibilities
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__insurance_responsibilities,
                destination: :prep__insurance_responsibilities
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
