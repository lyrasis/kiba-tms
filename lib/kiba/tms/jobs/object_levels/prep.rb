# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectLevels
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__object_levels,
                destination: :prep__object_levels
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
