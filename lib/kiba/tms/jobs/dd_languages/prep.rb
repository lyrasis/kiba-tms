# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DDLanguages
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dd_languages,
                destination: :prep__dd_languages
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
