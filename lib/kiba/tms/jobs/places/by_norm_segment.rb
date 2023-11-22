# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module ByNormSegment
          module_function

          def job
            return unless config.final_cleanup_done

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__ingest,
                destination: :places__by_norm_segment
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
                to: :segment
              transform Explode::RowsFromMultivalField,
                field: :segment,
                delim: " < "
              transform Deduplicate::Table,
                field: :segment
              transform Cspace::NormalizeForID,
                source: :segment,
                target: :normsegment
              transform Deduplicate::Table,
                field: :normsegment
              transform Delete::Fields,
                fields: :segment
            end
          end
        end
      end
    end
  end
end
