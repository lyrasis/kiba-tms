# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module RefFormats
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__ref_formats,
                destination: :prep__ref_formats
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :format
            end
          end
        end
      end
    end
  end
end
