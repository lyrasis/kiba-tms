# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module IndemnityResponsibilities
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__indemnity_responsibilities,
                destination: :prep__indemnity_responsibilities
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: Tms::IndemnityResponsibilities.delete_fields
              transform Tms::Transforms::DeleteNoValueTypes, field: :responsibility
            end
          end
        end
      end
    end
  end
end
