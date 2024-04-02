# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjInsurance
        module Migrating
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_insurance,
                destination: :obj_insurance__migrating
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :dropping
            end
          end
        end
      end
    end
  end
end
