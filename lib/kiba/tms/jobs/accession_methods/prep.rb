# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AccessionMethods
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__accession_methods,
                destination: :prep__accession_methods
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
