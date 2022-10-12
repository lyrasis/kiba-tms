# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConToDeduplicateAgainst
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__raw,
                destination: :name_compile__from_con_to_deduplicate_against
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
              transform Tms::Transforms::Constituents::NormalizeContype
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform Delete::FieldsExcept, fields: %i[combined]
              transform Deduplicate::Table, field: :combined
            end
          end
        end
      end
    end
  end
end
