# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationPurposes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__valuation_purposes,
                destination: :prep__valuation_purposes
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
