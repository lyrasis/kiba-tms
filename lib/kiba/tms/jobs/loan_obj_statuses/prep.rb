# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanObjStatuses
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__loan_obj_statuses,
                destination: :prep__loan_obj_statuses
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
