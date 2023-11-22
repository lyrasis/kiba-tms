# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptNomenclature
        module Lookup
          module_function

          def job
            return if Tms::Objects.objectname_controlled_source_fields.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.compile_sources,
                destination: :concept_nomenclature__lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Cspace::NormalizeForID,
                source: :objectname,
                target: :norm
              transform Replace::NormWithMostFrequentlyUsedForm,
                normfield: :norm,
                nonnormfield: :objectname,
                target: :use
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
