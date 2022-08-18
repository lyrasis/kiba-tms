# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConGeoCodes
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_geo_codes,
                destination: :prep__con_geo_codes
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :congeocode
            end
          end
        end
      end
    end
  end
end
