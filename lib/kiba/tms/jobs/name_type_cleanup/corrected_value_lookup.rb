# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module CorrectedValueLookup
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_compile,
                destination: :name_type_cleanup__corrected_value_lookup,
                lookup: :name_type_cleanup__returned_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[name correctname authoritytype correctauthoritytype
                  cleanupid]
              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[correctname correctauthoritytype]
              transform Tms::Transforms::NameTypeCleanup::ExplodeMultiNames,
                lookup: name_type_cleanup__returned_compile,
                keycolumn: :cleanupid,
                target: :correctname
              transform Delete::Fields,
                fields: %i[cleanupid]
              transform Tms::Transforms::Names::NormalizeContype,
                source: :authoritytype,
                target: :contype
              transform Tms::Transforms::Names::AddDefaultContype,
                target: :contype

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype name],
                target: :corrfingerprint,
                delim: " ",
                delete_sources: false
              transform Delete::Fields,
                fields: %i[name authoritytype contype]
            end
          end
        end
      end
    end
  end
end
