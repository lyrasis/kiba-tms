# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module RelatedDuplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__raw,
                destination: :name_compile__related_duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :relation_type, value: 'contact_person'
              transform Tms::Transforms::Names::NormalizeContype
              transform Delete::FieldsExcept, fields: %i[fingerprint contype_norm norm related_term related_role]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm related_term related_role],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform Deduplicate::FlagAll, on_field: :combined, in_field: :duplicate_all, explicit_no: false
              transform FilterRows::FieldPopulated, action: :keep, field: :duplicate_all
              transform Deduplicate::Flag, on_field: :combined, in_field: :duplicate,
                using: {}, explicit_no: false
              transform Delete::FieldsExcept, fields: %i[fingerprint duplicate_all duplicate]
            end
          end
        end
      end
    end
  end
end
