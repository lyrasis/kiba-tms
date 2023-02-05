# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module VariantsFromDuplicateConstituents
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__duplicates,
                destination: :name_compile__variants_from_duplicate_constituents,
                lookup: :constituents__for_compile
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Flag, on_field: :combined, in_field: :duplicate, using: {}, explicit_no: false
              transform FilterRows::FieldPopulated, action: :keep, field: :duplicate

              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.variants_from_duplicates'
              transform Merge::MultiRowLookup,
                lookup: constituents__for_compile,
                keycolumn: :combined,
                fieldmap: {mainname: Tms::Constituents.preferred_name_field},
                conditions: ->(origrow, mergerows) do
                  namefield = Tms::Constituents.preferred_name_field
                  thisname = origrow[namefield].downcase
                  mergerows.reject{ |mrow| thisname == mrow[namefield].downcase }
                end

              transform FilterRows::FieldPopulated, action: :keep, field: :mainname

              transform Rename::Fields, fieldmap: {
                Tms::Constituents.preferred_name_field => :varname,
                mainname: Tms::Constituents.preferred_name_field
              }

              transform Tms::Transforms::NameCompile::DeriveVariantName, mode: :main, from: :varname
            end
          end
        end
      end
    end
  end
end
