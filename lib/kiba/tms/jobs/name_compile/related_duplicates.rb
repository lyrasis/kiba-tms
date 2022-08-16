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
              transform Delete::FieldsExcept, fields: %i[fingerprint contype name related_term related_role]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype name related_term related_role],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform Deduplicate::FlagAll, on_field: :combined, in_field: :duplicate, explicit_no: false
              transform FilterRows::FieldPopulated, action: :keep, field: :duplicate
              transform Delete::FieldsExcept, fields: %i[fingerprint duplicate]
            end
          end
        end
      end
    end
  end
end
