# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module SurveyAttrTypes
        module Prep
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__survey_attr_types,
                destination: :prep__survey_attr_types
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
