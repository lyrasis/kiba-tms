# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module AllClean
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :valuation_control__all,
                destination: :valuation_control__all_clean
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[objinsuranceid objectnumber]
            end
          end
        end
      end
    end
  end
end
