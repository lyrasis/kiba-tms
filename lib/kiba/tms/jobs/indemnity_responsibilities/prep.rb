# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module IndemnityResponsibilities
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__indemnity_responsibilities,
                destination: :prep__indemnity_responsibilities
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
