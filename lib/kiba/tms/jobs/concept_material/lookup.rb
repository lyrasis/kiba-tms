# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptMaterial
        module Lookup
          module_function

          def job
            return if Tms::Objects.material_controlled_source_fields.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.compile_sources,
                destination: :concept_material__lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Copy::Field,
                from: :material,
                to: :materialfin
              if Tms.final_data_cleaner
                transform Tms.final_data_cleaner, fields: :materialfin
              end
              transform Cspace::NormalizeForID,
                source: :materialfin,
                target: :norm
              transform Replace::NormWithMostFrequentlyUsedForm,
                normfield: :norm,
                nonnormfield: :material,
                target: :use
              transform Deduplicate::Table,
                field: :material
              transform Delete::Fields,
                fields: %i[norm materialfin]
            end
          end
        end
      end
    end
  end
end
