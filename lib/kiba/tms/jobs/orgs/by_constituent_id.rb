# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Orgs
        module ByConstituentId
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: :orgs__by_constituentid
              },
              transformer: xforms
            )
          end

          def source
            iteration = Tms::Names.cleanup_iteration
            if iteration
              "nameclean#{iteration}__orgs_kept".to_sym
            else
              :constituents__orgs
            end
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

