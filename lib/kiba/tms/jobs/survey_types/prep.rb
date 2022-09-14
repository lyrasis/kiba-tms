# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module SurveyTypes
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__survey_types,
                destination: :prep__survey_types
              },
              transformer: config.multitable_xforms(binding)
            )
          end
        end
      end
    end
  end
end
