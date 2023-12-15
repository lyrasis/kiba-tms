# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptMaterial
        module FromPapersupport
          module_function

          def job
            return unless Tms::Objects.materialcontrolled_source_fields
              .include?(:papersupport)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__merged_data_prep,
                destination: :concept_material__from_papersupport
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              field = :papersupport_materialcontrolled
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: field
              transform Delete::FieldsExcept,
                fields: field
              transform Explode::RowsFromMultivalField,
                field: field,
                delim: Tms.delim
              transform Rename::Field,
                from: field,
                to: :material
              transform Merge::ConstantValue,
                target: :termsourcedetail,
                value: "TMS Objects.papersupport"
            end
          end
        end
      end
    end
  end
end
