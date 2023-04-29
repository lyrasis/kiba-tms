# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectTypes
        module Prep
          extend self

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__object_types,
                destination: :prep__object_types
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
