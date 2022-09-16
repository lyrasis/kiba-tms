# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TransStatus
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__trans_status,
                destination: :prep__trans_status
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
