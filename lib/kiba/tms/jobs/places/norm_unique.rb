# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module NormUnique
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__orig_normalized,
                destination: :places__norm_unique,
                lookup: :places__orig_normalized
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::Fields,
                fields: [config.derived_note_fields, :occurrences,
                  :normalized, :orig_combined].flatten
              transform Deduplicate::Table,
                field: :norm_combined,
                delete_field: false
              transform Sort::ByFieldValue,
                field: :norm_combined,
                mode: :string
              transform Merge::MultiRowLookup,
                lookup: places__orig_normalized,
                keycolumn: :norm_combined,
                fieldmap: {occurrences: :occurrences},
                delim: Tms.delim
              # sum the occurrences values
              transform do |row|
                occval = row[:occurrences]
                next row if occval.blank?
                next row unless occval[Tms.delim]

                row[:occurrences] = occval.split(Tms.delim)
                  .map(&:to_i)
                  .sum
                row
              end
              transform Fingerprint::Add,
                fields: config.source_fields,
                target: :norm_fingerprint
            end
          end
        end
      end
    end
  end
end
