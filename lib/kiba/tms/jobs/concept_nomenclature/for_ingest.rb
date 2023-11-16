# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptNomenclature
        module ForIngest
          module_function

          def job
            return unless Tms::Objects.objectname_controlled

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :concept_nomenclature__extract,
                destination: :concept_nomenclature__for_ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :preferredform
              transform Deduplicate::Table,
                field: :preferredform
              transform Rename::Field,
                from: :preferredform,
                to: :termdisplayname
            end
          end
        end
      end
    end
  end
end
