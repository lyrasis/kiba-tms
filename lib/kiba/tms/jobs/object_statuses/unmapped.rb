# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectStatuses
        module Unmapped
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__object_statuses,
                destination: :object_statuses__unmapped
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :objectstatus, value: 'NEEDS MAPPING'
           end
          end
        end
      end
    end
  end
end
