# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module IndemnityResponsibilities
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__indemnity_responsibilities,
              destination: :prep__indemnity_responsibilities
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields, fields: %i[system]
            transform FilterRows::FieldMatchRegexp,
              action: :reject,
              field: :responsibility,
              match: '^Not Assigned$'
          end
        end
      end
    end
  end
end
