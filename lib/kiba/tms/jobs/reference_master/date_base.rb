# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module DateBase
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__places_finalized,
                destination: :reference_master__date_base
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :drop
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :displaydate
              transform Delete::FieldsExcept,
                fields: %i[heading displaydate publisherorganizationlocal
                  pubplace edition numofpages]
              transform Rename::Fields, fieldmap: {
                publisherorganizationlocal: :publisher,
                pubplace: :publicationplaceplacelocal,
                numofpages: :pages
              }
            end
          end
        end
      end
    end
  end
end
