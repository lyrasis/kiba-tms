# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Dropping
          module_function

          def job
            return unless config.used
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :obj_locations__dropping
              },
              transformer: xforms
            )
          end

          def sources
            base = %i[
              obj_locations__dropping_no_location
              obj_locations__dropping_no_object
            ]
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            # do nothing
          end
        end
      end
    end
  end
end
