# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjInsurance
        module DroppedInContext
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_insurance,
                destination: :obj_insurance__dropped_in_context
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Sort::ByFieldValue,
                field: :objectnumber,
                mode: :string
              transform Delete::Fields,
                fields: :objinsuranceid
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
