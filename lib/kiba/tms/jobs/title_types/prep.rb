# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TitleTypes
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__title_types,
                destination: :prep__title_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :titletype
            end
          end
        end
      end
    end
  end
end
