# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module CleanedUnique
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__norm_unique_cleaned,
                destination: :places__cleaned_unique,
                lookup: :places__norm_unique_cleaned
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.cleanup_done
              transform Deduplicate::Table,
                field: :clean_combined,
                delete_field: false
              transform Delete::Fields,
                fields: %i[norm_combined norm_fingerprint occurrences]
              transform Merge::MultiRowLookup,
                lookup: places__norm_unique_cleaned,
                keycolumn: :clean_combined,
                fieldmap: {
                  norm_fingerprints: :norm_fingerprint,
                  norm_combineds: :norm_combined,
                  occurrences: :occurrences
                },
                delim: config.norm_fingerprint_delim
              transform do |row|
                occ = row[:occurrences]
                next row if occ.blank?

                occs = occ.split(config.norm_fingerprint_delim)
                  .map(&:to_i)
                  .sum
                row[:occurrences] = occs
                row
              end
              else
                transform Rename::Fields, fieldmap: {
                  norm_fingerprint: :norm_fingerprints,
                  norm_combined: :norm_combineds
                }
              end
            end
          end
        end
      end
    end
  end
end
