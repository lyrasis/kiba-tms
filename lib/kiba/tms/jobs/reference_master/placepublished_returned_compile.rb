# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PlacepublishedReturnedCompile
          module_function

          def job
            return unless config.placepublished_done
            return if config.placepublished_returned.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.placepublished_returned_jobs,
                destination: :reference_master__placepublished_returned_compile
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: %i[placepublished publisher merge_fingerprint]
              transform Deduplicate::Table,
                field: :merge_fingerprint,
                delete_field: false
              transform Fingerprint::FlagChanged,
                fingerprint: :merge_fingerprint,
                source_fields: %i[placepublished publisherorganizationlocal],
                delim: "␟",
                delete_fp: false,
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
