# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ConstituentDuplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__raw,
                destination: :name_compile__constituent_duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :relation_type, value: '_main term'
              transform FilterRows::FieldMatchRegexp,
                action: :keep,
                field: :termsource,
                match: '^TMS Constituents\.(orgs|persons)$'
              transform Delete::FieldsExcept, fields: %i[fingerprint contype norm]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype norm],
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