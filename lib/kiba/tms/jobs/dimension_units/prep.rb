# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionUnits
        module Prep
          extend self
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimension_units,
                destination: :prep__dimension_units
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
