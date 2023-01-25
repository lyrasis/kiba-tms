# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextStatuses
        module Prep
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__text_statuses,
                destination: :prep__text_statuses
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
