# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DispositionMethods
        module Prep
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__disposition_methods,
                destination: :prep__disposition_methods
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
