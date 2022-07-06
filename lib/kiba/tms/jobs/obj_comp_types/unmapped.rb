# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjCompTypes
        module Unmapped
          module_function

          def job
            return if Tms.excluded_tables.any?('ObjCompTypes.csv')
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_comp_types,
                destination: :obj_comp_types__unmapped
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :objcomptype, value: 'NEEDS MAPPING'
           end
          end
        end
      end
    end
  end
end
