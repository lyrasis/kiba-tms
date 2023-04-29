# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Classifications
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__classifications,
                destination: :prep__classifications
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
