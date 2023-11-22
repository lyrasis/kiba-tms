# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module ByNormWord
          module_function

          def job
            return unless config.final_cleanup_done

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__ingest,
                destination: :places__by_norm_word
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :termdisplayname
              transform Rename::Field,
                from: :termdisplayname,
                to: :word
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :word,
                find: " < ",
                replace: " "
              transform Explode::RowsFromMultivalField,
                field: :word,
                delim: " "
              transform Deduplicate::Table,
                field: :word
              transform Cspace::NormalizeForID,
                source: :word,
                target: :normword
              transform Deduplicate::Table,
                field: :normword
              transform Delete::Fields,
                fields: :word
            end
          end
        end
      end
    end
  end
end
