# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module ToClient0
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__compiled,
                destination: :locs__to_client_0
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :location_name,
                delete_field: false
            end
          end
        end
      end
    end
  end
end
