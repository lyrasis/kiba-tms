# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Persons
        module ByConstituentId
          module_function

          ITERATION = Tms.names.cleanup_iteration

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "nameclean#{ITERATION}__persons_kept".to_sym,
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

