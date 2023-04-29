# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjCompStatuses
        module Prep
          extend self

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_comp_statuses,
                destination: :prep__obj_comp_statuses
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
