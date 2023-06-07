# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module ReturnedCompile
          module_function

          def job
            return unless config.cleanup_done

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.returned_jobs,
                destination: :places__returned_compile
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::Fields,
                fields: %i[to_review]
              transform Deduplicate::Table,
                field: :clean_combined,
                delete_field: false
              transform Fingerprint::FlagChanged,
                fingerprint: :clean_fingerprint,
                source_fields: config.source_fields,
                delete_fp: true,
                target: :corrected
              transform Delete::FieldnamesStartingWith,
                prefix: "fp_"
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
