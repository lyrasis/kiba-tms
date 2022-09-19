# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Roles
        # Omits merging in RoleTypes because we don't really need/care about that categorization
        #   for the migration.
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__roles,
                destination: :prep__roles
              },
              transformer: config.xforms(binding)
            )
          end
        end
      end
    end
  end
end
