# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module ByConstituentId
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__persons,
                destination: :persons__by_constituentid
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
            end
          end
        end
      end
    end
  end
end
