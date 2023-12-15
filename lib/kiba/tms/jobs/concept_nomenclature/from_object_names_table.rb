# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptNomenclature
        module FromObjectNamesTable
          module_function

          def job
            return unless Tms::ObjectNames.used? &&
              Tms::Objects.objectnamecontrolled_source_fields.include?(:on)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__merged_data_prep,
                destination: :concept_nomenclature__from_object_names_table
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              field = :on_objectnamecontrolled
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
                to: :objectname
              transform Merge::ConstantValue,
                target: :termsourcedetail,
                value: "TMS ObjectNames.objectname"
            end
          end
        end
      end
    end
  end
end
