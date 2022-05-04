# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Countries
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__countries,
                destination: :prep__countries
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :country,
                match: '\([Nn]one [Aa]ssigned\)'
            end
          end
        end
      end
    end
  end
end
