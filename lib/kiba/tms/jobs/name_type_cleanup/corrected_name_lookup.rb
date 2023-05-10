# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module CorrectedNameLookup
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_compile,
                destination: :name_type_cleanup__corrected_name_lookup,
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
              transform Tms::Transforms::NameTypeCleanup::MergeCorrectData,
                lookup: name_type_cleanup__returned_compile,
                keycolumn: :cleanupid
              transform Tms::Transforms::NameTypeCleanup::ExplodeMultiNames,
                target: :correctname
              transform Tms::Transforms::NameTypeCleanup::OverlayType,
                target: :authoritytype
              transform Tms::Transforms::Names::NormalizeContype,
                source: :authoritytype,
                target: :contype
              transform Tms::Transforms::Names::AddDefaultContype
              transform do |row|
                corrname = row[:correctname]
                next row unless corrname.blank?

                row[:correctname] = row[:name]
                row
              end
              transform Delete::Fields,
                fields: %i[name authoritytype correctauthoritytype cleanupid]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype correctname],
                target: :corrfingerprint,
                delim: " ",
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
