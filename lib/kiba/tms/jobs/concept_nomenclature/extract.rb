# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptNomenclature
        module Extract
          module_function

          def job
            return unless Tms::Objects.objectname_controlled

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__shape,
                destination: :concept_nomenclature__extract
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: :objectname
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :objectname
              transform Explode::RowsFromMultivalField,
                field: :objectname,
                delim: Tms.delim
              transform Cspace::NormalizeForID,
                source: :objectname,
                target: :norm
              transform Replace::NormWithMostFrequentlyUsedForm,
                normfield: :norm,
                nonnormfield: :objectname,
                target: :preferredform
              transform Deduplicate::Table,
                field: :objectname
              transform Delete::Fields,
                fields: :norm
            end
          end
        end
      end
    end
  end
end
