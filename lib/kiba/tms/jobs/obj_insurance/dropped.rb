# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjInsurance
        module Dropped
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_insurance,
                destination: :obj_insurance__dropped
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :dropping
              transform Delete::Fields,
                fields: :dropping
            end
          end
        end
      end
    end
  end
end
