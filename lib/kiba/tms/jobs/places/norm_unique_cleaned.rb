# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module NormUniqueCleaned
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__norm_unique,
                destination: :places__norm_unique_cleaned,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :places__corrections if config.cleanup_done
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Append::NilFields,
                fields: config.worksheet_added_fields

              if config.cleanup_done
                if lookups.any?(:places__corrections)
                  transform Fingerprint::MergeCorrected,
                    lookup: places__corrections,
                    keycolumn: :norm_fingerprint,
                    todofield: :corrected
                end
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.source_fields,
                  target: :clean_combined,
                  delim: "|||",
                  prepend_source_field_name: true,
                  delete_sources: false
              else
                transform Copy::Field,
                  from: :norm_combined,
                  to: :clean_combined
              end
            end
          end
        end
      end
    end
  end
end
