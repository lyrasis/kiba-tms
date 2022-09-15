# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextTypes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__text_types,
                destination: :prep__text_types,
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
