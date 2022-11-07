# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaStatuses
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__media_statuses,
                destination: :prep__media_statuses
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
