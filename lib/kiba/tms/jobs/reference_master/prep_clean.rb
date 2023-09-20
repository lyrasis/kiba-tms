# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PrepClean
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__reference_master,
                destination: :reference_master__prep_clean,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.placepublished_done
              base << :reference_master__placepublished_corrections
            end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

              transform Fingerprint::Add,
                fields: %i[placepublished publisherorganizationlocal],
                target: :orig_pub_fingerprint

              if lookups.any?(:reference_master__placepublished_corrections)
                transform Fingerprint::MergeCorrected,
                  lookup: reference_master__placepublished_corrections,
                  keycolumn: :orig_pub_fingerprint,
                  todofield: :corrected
                transform Clean::EnsureConsistentFields
              end
            end
          end
        end
      end
    end
  end
end
