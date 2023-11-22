# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module Ingest
          module_function

          def job
            return unless config.final_cleanup_done

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__authority_lookup,
                destination: :places__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :use
              transform Deduplicate::Table,
                field: :use
              transform Rename::Field,
                from: :use,
                to: :termdisplayname
            end
          end
        end
      end
    end
  end
end
