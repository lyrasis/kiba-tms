# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module EMailTypes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__email_types,
                destination: :prep__email_types
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
