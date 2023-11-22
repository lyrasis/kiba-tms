# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptNomenclature
        module FromObjectname
          module_function

          def job
            return if Tms::Objects.objectname_controlled_source_fields.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__objects,
                destination: :concept_nomenclature__from_objectname
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
              transform Merge::ConstantValue,
                target: :termsourcedetail,
                value: "TMS Objects.objectname"
            end
          end
        end
      end
    end
  end
end
