# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjCompStatuses
        module Unmapped
          module_function

          def job
            return if Tms.excluded_tables.any?('ObjCompStatuses')
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_comp_statuses,
                destination: :obj_comp_statuses__unmapped
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :objcompstatus, value: 'NEEDS MAPPING'
           end
          end
        end
      end
    end
  end
end
