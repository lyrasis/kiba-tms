# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TitleTypes
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__title_types,
                destination: :prep__title_types
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
