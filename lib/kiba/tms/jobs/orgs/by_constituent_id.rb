# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Orgs
        module ByConstituentId
          module_function

          ITERATION = Tms.names.cleanup_iteration

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "nameclean#{ITERATION}__orgs_kept".to_sym,
                destination: :orgs__by_constituentid
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

