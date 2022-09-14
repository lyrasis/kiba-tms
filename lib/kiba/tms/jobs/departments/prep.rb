# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Departments
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__departments,
                destination: :prep__departments
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
