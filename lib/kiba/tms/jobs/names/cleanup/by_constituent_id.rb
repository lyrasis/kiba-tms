# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup
          module ByConstituentId
            module_function

            ITERATION = Tms.names.cleanup_iteration

            def job
              Kiba::Extend::Jobs::Job.new(
                files: {
                  source: sources,
                  destination: :nameclean__by_constituentid
                },
                transformer: xforms
              )
            end

            def sources
              if ITERATION
                [
                  "nameclean#{ITERATION}__constituents_kept".to_sym,
                  "nameclean#{ITERATION}__orgs_not_kept".to_sym,
                  "nameclean#{ITERATION}__persons_not_kept".to_sym
                ]
              else
                :prep__constituents
              end
            end

            def xforms
              Kiba.job_segment do
                transform Tms::Transforms::Names::ExtractConstituentIds
                transform Deduplicate::Table, field: :constituentid, delete_field: false
              end
            end
          end
        end
      end
    end
  end
end
