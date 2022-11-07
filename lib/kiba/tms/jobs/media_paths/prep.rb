# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaPaths
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__media_paths,
                destination: :prep__media_paths
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
