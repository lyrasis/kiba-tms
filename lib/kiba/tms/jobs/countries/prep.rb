# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Countries
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__countries,
                destination: :prep__countries
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
