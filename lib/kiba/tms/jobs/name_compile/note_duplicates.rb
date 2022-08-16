# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module NoteDuplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__raw,
                destination: :name_compile__note_duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldMatchRegexp, action: :keep, field: :relation_type, match: '_note$'
              transform Delete::FieldsExcept, fields: %i[fingerprint contype name relation_type note_text]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype name relation_type note_text],
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
