# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module Cleanup
          module ByConstituentId
            module_function

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
              if Tms::Names.cleanup_iteration
                iter = Tms::Names.cleanup_iteration
                [
                  "nameclean#{iter}__constituents_kept".to_sym,
                  "nameclean#{iter}__orgs_not_kept".to_sym,
                  "nameclean#{iter}__persons_not_kept".to_sym
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
