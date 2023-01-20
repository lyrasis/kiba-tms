# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AddressTypes
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__address_types,
                destination: :prep__address_types
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
