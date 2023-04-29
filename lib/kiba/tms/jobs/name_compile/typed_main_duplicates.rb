# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module TypedMainDuplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__raw,
                destination: :name_compile__typed_main_duplicates
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :relation_type,
                value: "_main term"
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :contype
              transform Tms::Transforms::Names::NormalizeContype
              transform Delete::FieldsExcept,
                fields: %i[fingerprint contype_norm norm termsource]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm],
                target: :combined,
                sep: " ",
                delete_sources: false
              transform Deduplicate::FlagAll,
                on_field: :combined,
                in_field: :duplicate_all,
                explicit_no: false
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :duplicate_all
              transform Deduplicate::Flag,
                on_field: :combined,
                in_field: :duplicate,
                using: {},
                explicit_no: false
              # We do not deduplicate names from Constituents. Since these names
              #   will be referenced by ID from many places in the migration, we
              #   need to keep all rows except for those being dropped. Clients
              #   also need to see the duplicate values so they can
              #   disambiguate them if appropriate.
              # However, we want to remove non-constituent main terms if they
              #   duplicate main terms.
              transform FilterRows::FieldMatchRegexp,
                action: :reject,
                field: :termsource,
                match: '^TMS Constituents\.(orgs|persons)$'
              transform Delete::FieldsExcept,
                fields: %i[fingerprint duplicate_all duplicate combined]
            end
          end
        end
      end
    end
  end
end
