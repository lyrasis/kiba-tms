# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptNomenclature
        module Ingest
          module_function

          def job
            return if Tms::Objects.objectname_controlled_source_fields.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :concept_nomenclature__lookup,
                destination: :concept_nomenclature__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: :objectname
              transform Deduplicate::Table,
                field: :use
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :use,
                value: "%NULLVALUE%"
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
