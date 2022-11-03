# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectNameTypes
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__object_name_types,
                destination: :prep__object_name_types
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
