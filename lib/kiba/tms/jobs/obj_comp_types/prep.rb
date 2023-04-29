# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjCompTypes
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_comp_types,
                destination: :prep__obj_comp_types
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
