# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module LmiExploded
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__lmi,
                destination: :obj_locations__lmi_exploded
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Explode::RowsFromMultivalField,
                field: :objectnumber,
                delim: Tms.delim
            end
          end
        end
      end
    end
  end
end
