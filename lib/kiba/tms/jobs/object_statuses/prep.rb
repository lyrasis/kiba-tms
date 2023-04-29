# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectStatuses
        module Prep
          extend self

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__object_statuses,
                destination: :prep__object_statuses
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
