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
              transform FilterRows::FieldEqualTo, action: :keep, field: :relation_type, value: 'main term'
              transform FilterRows::FieldMatchRegexp,
                action: :keep,
                field: :termsource,
                match: '^TMS Constituents\.(orgs|persons)$'
              transform Delete::FieldsExcept, fields: %i[fingerprint contype name]
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID, source: :name, target: :norm
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype norm],
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
