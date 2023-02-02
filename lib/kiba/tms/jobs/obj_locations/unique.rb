# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Unique
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__migrating,
                destination: :obj_locations__unique
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[objlocationid objectnumber]
              transform Deduplicate::Table, field: :fingerprint
            end
          end
        end
      end
    end
  end
end
