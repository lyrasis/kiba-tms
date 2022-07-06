# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionElements
        module Unmapped
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__dimension_elements,
                destination: :dimension_elements__unmapped
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :element, value: 'NEEDS MAPPING'
           end
          end
        end
      end
    end
  end
end
