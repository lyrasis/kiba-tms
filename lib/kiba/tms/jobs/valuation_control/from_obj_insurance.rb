# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module FromObjInsurance
          module_function

          def job
            return unless Tms::ObjInsurance.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_insurance__shape,
                destination: :valuation_control__from_obj_insurance
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Copy::Field,
                from: :objectnumber,
                to: :idbase
            end
          end
        end
      end
    end
  end
end
