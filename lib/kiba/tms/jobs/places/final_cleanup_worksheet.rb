# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module FinalCleanupWorksheet
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__init_cleaned_terms,
                destination: :places__final_cleanup_worksheet,
                lookup: :places__init_cleaned_terms
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: :norm
              transform Deduplicate::Table,
                field: :norm
              transform Merge::MultiRowLookup,
                lookup: places__init_cleaned_terms,
                keycolumn: :norm,
                fieldmap: {orig: :orig},
                conditions: ->(r, rows) { rows.uniq { |row| row[:orig] } }
              transform Count::FieldValues, field: :orig, target: :orig_ct
              transform Append::NilFields,
                fields: %i[normalized_variants add_variant]
              transform Append::NilFields,
                fields: %i[]
              transform do |row|
                origct = row[:orig_ct]
                next row unless origct.to_i > 1

                row[:normalized_variants] = "y"
                row
              end
              transform Rename::Field,
                from: :norm,
                to: :place
              transform Fingerprint::Add,
                fields: config.final_wksht_fp_fields,
                target: :fingerprint
            end
          end
        end
      end
    end
  end
end
