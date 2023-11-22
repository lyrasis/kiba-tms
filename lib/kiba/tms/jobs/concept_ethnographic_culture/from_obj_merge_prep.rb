# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptEthnographicCulture
        module FromObjMergePrep
          module_function

          def job(field:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__merged_data_prep,
                destination:
                "concept_ethnographic_culture__from_#{field}".to_sym
              },
              transformer: xforms(field)
            )
          end

          def xforms(field)
            Kiba.job_segment do
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
                to: :culture
              transform Merge::ConstantValue,
                target: :termsourcedetail,
                value: "TMS Objects.#{field}"
            end
          end
        end
      end
    end
  end
end
