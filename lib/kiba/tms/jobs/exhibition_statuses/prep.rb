# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhibitionStatuses
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exhibition_statuses,
                destination: :prep__exhibition_statuses
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
