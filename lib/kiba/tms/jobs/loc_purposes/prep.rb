# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocPurposes
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loc_purposes,
                destination: :prep__loc_purposes
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
