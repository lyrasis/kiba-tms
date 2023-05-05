# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module VariantDuplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__raw,
                destination: :name_compile__variant_duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep,
                field: :relation_type, value: "variant term"
              transform Tms::Transforms::Names::NormalizeContype
              transform Delete::FieldsExcept,
                fields: %i[fingerprint contype_norm norm variant_term
                  variant_qualifier]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm variant_term variant_qualifier],
                target: :combined,
                delim: " ",
                delete_sources: false
              transform Deduplicate::FlagAll, on_field: :combined,
                in_field: :duplicate_all, explicit_no: false
              transform FilterRows::FieldPopulated, action: :keep,
                field: :duplicate_all
              transform Deduplicate::Flag, on_field: :combined,
                in_field: :duplicate, explicit_no: false, using: {}
              transform Delete::FieldsExcept,
                fields: %i[fingerprint duplicate_all duplicate]
            end
          end
        end
      end
    end
  end
end
